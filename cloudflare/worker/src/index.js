const securityHeaders = {
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "X-Frame-Options": "DENY",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      ...securityHeaders,
    },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      if (!env.DB) {
        return json({ ok: false, service: "coki-api", database: "not_configured" }, 503);
      }

      try {
        await env.DB.prepare("SELECT 1 AS ok").first();
        return json({
          ok: true,
          service: "coki-api",
          database: "connected",
          environment: env.ENVIRONMENT || "pilot",
        });
      } catch {
        // Do not expose database errors, SQL, credentials or internal configuration.
        return json({ ok: false, service: "coki-api", database: "unavailable" }, 503);
      }
    }

    return json({ error: "not_found" }, 404);
  },
};
