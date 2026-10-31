import { ApiError } from "../utils/api-error.js";

const actionInstructions = {
  "order-extraction":
    "Extract a tailoring order. Return a concise, editable JSON object with customerName, garment, dueDate, totalAmount, paidAmount, note, and missingFields. Use null for facts not provided; never invent values.",
  "measurement-extraction":
    "Extract garment measurements and units from the request. Return editable JSON with measurements, units, and fieldsNeedingConfirmation. Never infer a missing measurement.",
  "design-suggestions":
    "Suggest three practical garment design options based on the request. Clearly label suggestions as ideas, not saved customer preferences.",
  "fabric-calculator":
    "Estimate fabric requirements. Return an editable JSON estimate including garment, fabricWidth, meters, assumptions, and confidence. State every assumption and ask for missing inputs instead of presenting guesses as facts.",
  "price-estimator":
    "Estimate a tailoring price from explicitly provided shop rates and materials. Return editable JSON with labor, materials, total, assumptions, and missingInputs. Do not invent the shop's rate card.",
  "delivery-prediction":
    "Estimate a delivery date only from the provided workload and capacity. Return editable JSON with suggestedDate, confidence, and assumptions; state when there is insufficient data.",
  "whatsapp-message":
    "Draft a polite, concise WhatsApp message in the requested language. Return only editable message text; do not send it.",
  "business-dashboard":
    "Summarize only the business data supplied. Return concise JSON insights, trends, and uncertainties. Do not invent metrics.",
  "measurement-validation":
    "Review the supplied measurements for missing fields, inconsistent units, and unusual values. Flag items for human review; do not silently change measurements or diagnose a person.",
  "repeat-order":
    "Summarize the prior order details and propose a new editable order draft. Clearly list fields that need customer confirmation.",
  "voice-order":
    "Convert the supplied speech transcript into an editable tailoring order draft. Use null for unclear details and list what needs confirmation.",
};

export function createAiController(env) {
  return {
    run: async (req, res) => {
      if (!env.GEMINI_API_KEY) {
        throw new ApiError(503, "AI_NOT_CONFIGURED", "AI services are not configured on this server.");
      }

      const { text, context = {} } = req.body;
      const prompt = [
        "You are a tailoring-shop assistant. Follow the requested task without making up facts.",
        `Task: ${actionInstructions[req.params.action]}`,
        `User request: ${text}`,
        `Additional context: ${JSON.stringify(context)}`,
      ].join("\n\n");

      const models = [env.GEMINI_MODEL, env.GEMINI_FALLBACK_MODEL].filter(Boolean);
      const maxAttempts = 3;
      let response;

      outer: for (const model of models) {
        for (let attempt = 0; attempt < maxAttempts; attempt++) {
          try {
            response = await fetch(
              `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
              {
                method: "POST",
                headers: {
                  "content-type": "application/json",
                  "x-goog-api-key": env.GEMINI_API_KEY,
                },
                body: JSON.stringify({
                  contents: [{ parts: [{ text: prompt }] }],
                  generationConfig: { temperature: 0.3 },
                }),
                signal: AbortSignal.timeout(20000),
              },
            );
                    } catch (error) {
            console.error("AI provider request failed", {
              action: req.params.action,
              model,
              error: error?.name,
            });
            response = undefined;
            break; // slow or unreachable: move on to the next model
          }

          if (response.ok) break outer;

          console.error("AI provider returned an error", {
            action: req.params.action,
            model,
            attempt: attempt + 1,
            status: response.status,
          });

          // Only retry temporary errors; anything else moves to the next model.
          if (![429, 500, 503].includes(response.status)) break;
          if (attempt < maxAttempts - 1) {
            await new Promise((resolve) => setTimeout(resolve, 1000 * (attempt + 1)));
          }
        }
      }

      if (!response?.ok) {
        throw new ApiError(502, "AI_PROVIDER_ERROR", "The AI service could not complete this request.");
      }

      let providerResponse;
      try {
        providerResponse = await response.json();
      } catch (error) {
        console.error("AI provider returned invalid JSON", {
          action: req.params.action,
          error,
        });
        throw new ApiError(502, "AI_INVALID_RESPONSE", "The AI service returned an invalid response.");
      }

      const suggestion = providerResponse.candidates?.[0]?.content?.parts
        ?.map((part) => part.text ?? "")
        .join("")
        .trim();
      if (!suggestion) {
        throw new ApiError(502, "AI_EMPTY_RESPONSE", "The AI service returned no suggestion.");
      }

      res.json({
        success: true,
        data: { action: req.params.action, suggestion, requiresReview: true },
      });
    },
  };
}
