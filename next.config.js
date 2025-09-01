/** @type {import('next').NextConfig} */
const nextConfig = {
  // Force a unique build each deploy so chunks never mismatch
  generateBuildId: async () => String(Date.now()),
};
module.exports = nextConfig;
