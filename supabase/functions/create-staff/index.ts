import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import "https://deno.land/std@0.224.0/dotenv/load.ts";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type, x-api-key",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });

  try {
    const apiKey = req.headers.get("x-api-key");
    console.log("Received x-api-key:", apiKey);

    if (apiKey !== Deno.env.get("EDGE_FUNCTION_KEY")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: corsHeaders });
    }

    const { email, password } = await req.json();
    console.log("Payload received:", { email, password });

    if (!email || !password) {
      return new Response(JSON.stringify({ error: "Email and password required" }), { status: 400, headers: corsHeaders });
    }

    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SERVICE_ROLE_KEY")!);

    const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });

    if (createError || !newUser.user) throw createError;
    console.log("User created:", newUser.user.id);

    const { error: insertError } = await supabase.from("users").insert({
      id: newUser.user.id,
      email: newUser.user.email,
      role: "staff",
    });
    if (insertError) throw insertError;

    return new Response(JSON.stringify({ success: true, userId: newUser.user.id }), { status: 200, headers: corsHeaders });

  } catch (err) {
    console.error("Internal error:", err);
    return new Response(JSON.stringify({ error: err.message || "Internal server error" }), { status: 500, headers: corsHeaders });
  }
});
