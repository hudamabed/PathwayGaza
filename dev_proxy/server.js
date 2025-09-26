// dev_proxy/server.js

/* ✅ Polyfill for Node versions that don't have Object.hasOwn (ES2022) */
if (!Object.hasOwn) {
  Object.hasOwn = function (obj, key) {
    return Object.prototype.hasOwnProperty.call(obj, key);
  };
}

const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

// Your Django server
const target = process.env.BACKEND || 'http://localhost:8000';

// Add CORS headers for Flutter web (port changes every run)
app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (origin && /^http:\/\/localhost:\d+$/.test(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  } else {
    res.setHeader('Access-Control-Allow-Origin', '*');
  }
  res.setHeader('Vary', 'Origin');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PATCH,PUT,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization,Content-Type');

  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    return res.end();
  }
  next();
});

// Proxy /api/* -> Django /api/*
app.use(
  '/api',
  createProxyMiddleware({
    target,
    changeOrigin: true,
    xfwd: true,
    logLevel: 'silent',
    pathRewrite: (path) => path, // no rewrite, explicit
    onProxyRes: (proxyRes, req) => {
      // ensure CORS headers survive the proxy
      const origin = req.headers.origin;
      proxyRes.headers['access-control-allow-methods'] = 'GET,POST,PATCH,PUT,DELETE,OPTIONS';
      proxyRes.headers['access-control-allow-headers'] = 'Authorization,Content-Type';
      proxyRes.headers['vary'] = 'Origin';
      proxyRes.headers['access-control-allow-origin'] =
        origin && /^http:\/\/localhost:\d+$/.test(origin) ? origin : '*';
    },
  })
);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Dev API proxy running at http://localhost:${PORT}/api  ->  ${target}/api`);
});
