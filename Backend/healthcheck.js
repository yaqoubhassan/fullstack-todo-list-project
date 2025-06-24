const http = require("http");

const options = {
  hostname: "localhost",
  port: 3000,
  path: "/",
  method: "GET",
  timeout: 5000 // Increased timeout
};

const req = http.request(options, (res) => {
  console.log(`Health check response: ${res.statusCode}`);
  if (res.statusCode === 200) {
    console.log("Health check passed");
    process.exit(0);
  } else {
    console.log("Health check failed - wrong status code");
    process.exit(1);
  }
});

req.on("error", (error) => {
  console.log("Health check failed - error:", error.message);
  process.exit(1);
});

req.on("timeout", () => {
  console.log("Health check failed - timeout");
  req.destroy();
  process.exit(1);
});

req.end();
