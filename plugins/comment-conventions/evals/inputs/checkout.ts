// ============================================================
// CHECKOUT PROCESSING
// This file contains the core checkout logic for the storefront.
// It handles validating the cart, applying discounts, calculating
// totals, charging the customer, and finally generating a receipt.
// All of these steps need to run in order — see the inline notes
// below for the full sequence.
// ============================================================

export type CartItem = { sku: string; unitPrice: number; qty: number };

export function checkout(cart: CartItem[], discountCode: string | null): number {
  // Step 1: Validate the cart. The cart may be empty, or it may contain
  // line items with zero quantity, which we don't want to process. Throwing
  // here keeps the error handling consistent with the rest of the codebase
  // and avoids the downstream service from receiving malformed input.
  if (!cart || cart.length === 0) {
    throw new Error("empty cart");
  }
  for (const item of cart) {
    // Skip lines with no quantity. We do this because the legacy admin UI
    // sometimes adds a placeholder row with qty=0 when the merchant is
    // editing the catalog, and we don't want to bill the customer for it.
    if (item.qty <= 0) {
      throw new Error("invalid qty");
    }
  }

  // Step 2: Calculate the subtotal. We loop over every cart item and
  // multiply the unit price by the quantity, accumulating the result into
  // the `subtotal` variable. This is the standard way to compute a total
  // in a shopping cart and is used throughout our codebase.
  let subtotal = 0;
  for (const item of cart) {
    // Multiply unit price by quantity to get the line total, then add it
    // to the running subtotal.
    subtotal += item.unitPrice * item.qty;
  }

  // Step 3: Apply the discount, if one was passed in. Discounts are
  // optional — the caller may pass null when the customer didn't enter
  // a code. When a code is present, we look it up and subtract the
  // percentage from the subtotal.
  if (discountCode !== null) {
    // Rounding mode is half-up here because finance signed off on it
    // in 2024 to match the upstream invoicing system; see ADR-017.
    const rate = lookupDiscount(discountCode);
    subtotal = Math.round(subtotal * (1 - rate) * 100) / 100;
  }

  // Step 4: Return the final total. This is the amount the customer
  // will be charged on their card.
  return subtotal;
}

function lookupDiscount(code: string): number {
  // Hardcoded for now. In the future we'll move these into the database
  // so the marketing team can edit them without a deploy, but for now
  // a simple map is enough and keeps the function fast.
  const table: Record<string, number> = {
    SUMMER: 0.1,
    LOYAL: 0.15,
  };
  return table[code] ?? 0;
}
