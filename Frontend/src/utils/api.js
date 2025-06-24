const API_BASE_URL =
  process.env.NODE_ENV === "production"
    ? "/api" // This will use the nginx proxy in Docker
    : "http://localhost:3000/api";

export default API_BASE_URL;
