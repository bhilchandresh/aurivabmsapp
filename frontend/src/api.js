import axios from "axios";

// Automatically detect environment
const API_URL =
  import.meta.env.MODE === "development"
    ? "http://localhost:5001/api/v1"
    : "https://api.aurivabms.in/api/v1";

const api = axios.create({
  baseURL: API_URL,
  withCredentials: true,
});

export default api;
