const express = require('express');
const http = require('http');
const app = express();

let isShuttingDown = false;

let awsMetadata = {
  availabilityZone: null,
  cluster: null,
  fetched: false
};

const fetchAWSMetadata = () => {
  return new Promise((resolve) => {
    if (awsMetadata.fetched) {
      return resolve(awsMetadata);
    }
    const options = {
      hostname: '169.254.169.254',
      path: '/latest/meta-data/placement/availability-zone',
      method: 'GET',
      timeout: 1000
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        awsMetadata.availabilityZone = data.trim();
        awsMetadata.cluster = process.env.ECS_CLUSTER ||
                              process.env.CLUSTER_NAME ||
                              process.env.K8S_CLUSTER ||
                              'unknown';
        awsMetadata.fetched = true;
        resolve(awsMetadata);
      });
    });

    req.on('error', () => {
      awsMetadata.availabilityZone = 'local';
      awsMetadata.cluster = 'local';
      awsMetadata.fetched = true;
      resolve(awsMetadata);
    });

    req.on('timeout', () => {
      req.destroy();
      awsMetadata.availabilityZone = 'local';
      awsMetadata.cluster = 'local';
      awsMetadata.fetched = true;
      resolve(awsMetadata);
    });

    req.end();
  });
};

fetchAWSMetadata().then((metadata) => {
  log('info', 'AWS metadata loaded', metadata);
});

const log = (level, message, data = {}) => {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level: level.toUpperCase(),
    message,
    ...data
  };
  console.log(JSON.stringify(logEntry));
};

app.use((req, res, next) => {
  const startTime = Date.now();

  log('info', 'Incoming request', {
    method: req.method,
    url: req.url,
    ip: req.ip || req.connection.remoteAddress,
    userAgent: req.get('user-agent')
  });

  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const logData = {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`
    };

    if (res.statusCode === 200 && awsMetadata.fetched) {
      logData.awsCluster = awsMetadata.cluster;
      logData.awsZone = awsMetadata.availabilityZone;
    }

    log('info', 'Request completed', logData);
  });

  next();
});

app.use((req, res, next) => {
  if (isShuttingDown) {
    log('warn', 'Request rejected during shutdown', { method: req.method, url: req.url });
    return res.status(503).json({ error: 'Server is shutting down' });
  }
  next();
});

app.get('/health', (req, res) => {
  if (isShuttingDown) {
    log('warn', 'Health check during shutdown');
    return res.status(503).json({ status: 'shutting_down' });
  }

  log('debug', 'Health check endpoint accessed');
  res.status(200).json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api', (req, res) => {
  const hostname = require('os').hostname();
  log('debug', 'API endpoint accessed', { hostname });

  res.json({
    message: "200 :: API working",
    hostname: hostname
  });
});

app.use((req, res) => {
  log('warn', 'Route not found', {
    method: req.method,
    url: req.url,
    ip: req.ip || req.connection.remoteAddress
  });
  res.status(404).json({ error: 'Route not found' });
});

app.use((err, req, res) => {
  log('error', 'Internal server error', {
    error: err.message,
    stack: err.stack,
    method: req.method,
    url: req.url
  });
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = 3000;
const server = app.listen(PORT, () => {
  log('info', 'Server started successfully', {
    port: PORT,
    nodeVersion: process.version,
    platform: process.platform,
    pid: process.pid,
    hostname: require('os').hostname()
  });
});

const SHUTDOWN_TIMEOUT = 30000;

function gracefulShutdown(signal) {
  log('info', `${signal} received, starting graceful shutdown`, { pid: process.pid });
  isShuttingDown = true;

  server.close(() => {
    log('info', 'All connections closed, shutting down');
    process.exit(0);
  });

  setTimeout(() => {
    log('error', 'Shutdown timeout reached, forcing exit');
    process.exit(1);
  }, SHUTDOWN_TIMEOUT);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
