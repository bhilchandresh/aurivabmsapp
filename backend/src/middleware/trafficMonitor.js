const activeIPs = new Map();

// Helper to clean up IPs that haven't made a request in the last 15 minutes
setInterval(() => {
  const now = Date.now();
  for (const [ip, data] of activeIPs.entries()) {
    if (now - data.lastRequest > 15 * 60 * 1000) {
      activeIPs.delete(ip);
    }
  }
}, 5 * 60 * 1000); // Run cleanup every 5 minutes

const trafficMonitor = (req, res, next) => {
  try {
    const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress || req.ip;
    const cleanIp = clientIp.includes('::ffff:') ? clientIp.split('::ffff:')[1] : clientIp;

    if (activeIPs.has(cleanIp)) {
      const data = activeIPs.get(cleanIp);
      data.count += 1;
      data.lastRequest = Date.now();
    } else {
      activeIPs.set(cleanIp, { count: 1, lastRequest: Date.now() });
    }
  } catch (error) {
    console.error('Traffic Monitor Error:', error);
  }
  next();
};

// Expose the map so the security controller can read it
module.exports = {
  trafficMonitor,
  getActiveTraffic: () => {
    const trafficList = [];
    for (const [ip, data] of activeIPs.entries()) {
      trafficList.push({
        ipAddress: ip,
        count: data.count,
        lastRequest: new Date(data.lastRequest)
      });
    }
    // Sort by count descending
    return trafficList.sort((a, b) => b.count - a.count);
  }
};
