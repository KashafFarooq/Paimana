import "dotenv/config";

const res = await fetch(
  "https://generativelanguage.googleapis.com/v1beta/models?pageSize=100",
  { headers: { "x-goog-api-key": process.env.GEMINI_API_KEY } },
);
const json = await res.json();
console.log("Status:", res.status);
if (json.models) {
  console.log(
    json.models
      .filter((m) => m.supportedGenerationMethods?.includes("generateContent"))
      .map((m) => m.name)
      .join("\n"),
  );
} else {
  console.log(JSON.stringify(json, null, 2));
}