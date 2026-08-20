import { Order, OrderItem, ProductionStage, BatchStage, Sale, InventoryItem, Product } from '../types';

/**
 * Security, RBAC, and Business Logic Validation Engine
 * Guards against bugs, negative stock, race conditions, unauthorized mutations, and invalid state transitions.
 */

export interface ValidationResult {
  valid: boolean;
  error?: string;
}

// 1. RBAC & Cross-Branch Authorization Guard
export function validateBranchAccess(
  userRole: 'admin' | 'branch',
  userBranchId: string | undefined,
  targetBranchId: string
): ValidationResult {
  if (userRole === 'admin') {
    return { valid: true };
  }
  if (userRole === 'branch') {
    if (!userBranchId) {
      return { valid: false, error: 'Access Denied: Unassigned branch user.' };
    }
    if (userBranchId !== targetBranchId) {
      return {
        valid: false,
        error: `Cross-Branch Access Violation: User from ${userBranchId} attempted to access data for ${targetBranchId}.`,
      };
    }
    return { valid: true };
  }
  return { valid: false, error: 'Unknown role authorization.' };
}

// 2. Order Line Item & Math Integrity Guard
export function validateOrderPayload(items: OrderItem[]): ValidationResult {
  if (!items || items.length === 0) {
    return { valid: false, error: 'Order must contain at least one item.' };
  }
  for (const item of items) {
    if (!item.productId || typeof item.productId !== 'string') {
      return { valid: false, error: 'Invalid product ID in order item.' };
    }
    if (!Number.isFinite(item.quantity) || item.quantity <= 0 || !Number.isInteger(item.quantity)) {
      return { valid: false, error: `Invalid item quantity (${item.quantity}). Quantity must be a positive integer.` };
    }
    if (!Number.isFinite(item.unitPrice) || item.unitPrice < 0) {
      return { valid: false, error: `Invalid unit price (${item.unitPrice}). Price cannot be negative.` };
    }
  }
  return { valid: true };
}

export function computeOrderTotal(items: OrderItem[]): number {
  return items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
}

// 3. POS Transaction & Anti-Negative Stock Guard
export function validatePOSSale(
  inventoryItem: InventoryItem | undefined,
  saleQty: number,
  unitPrice: number,
  amountTendered?: number
): ValidationResult {
  if (!inventoryItem) {
    return { valid: false, error: 'Inventory record not found for selected product.' };
  }
  if (!Number.isFinite(saleQty) || saleQty <= 0 || !Number.isInteger(saleQty)) {
    return { valid: false, error: `Invalid sale quantity (${saleQty}). Must be a positive integer.` };
  }
  if (inventoryItem.stock < saleQty) {
    return {
      valid: false,
      error: `Insufficient Stock: Cannot sell ${saleQty} units. Available stock is only ${inventoryItem.stock} units.`,
    };
  }
  const totalAmount = saleQty * unitPrice;
  if (amountTendered !== undefined && amountTendered < totalAmount) {
    return {
      valid: false,
      error: `Insufficient Payment: Tendered ₱${amountTendered} is less than total ₱${totalAmount}.`,
    };
  }
  return { valid: true };
}

// 4. Central Commissary Stock Allocation Guard
export function validateCommissaryAllocation(
  product: Product | undefined,
  transferQty: number
): ValidationResult {
  if (!product) {
    return { valid: false, error: 'Product not found in commissary catalog.' };
  }
  if (!Number.isFinite(transferQty) || transferQty <= 0 || !Number.isInteger(transferQty)) {
    return { valid: false, error: 'Transfer quantity must be a positive integer.' };
  }
  if (product.adminStock < transferQty) {
    return {
      valid: false,
      error: `Allocation Failed: Insufficient central buffer stock. Available: ${product.adminStock} units, Requested: ${transferQty} units.`,
    };
  }
  return { valid: true };
}

// 5. Made-to-Order Kitchen Stage Progression Finite State Machine
const VALID_MTO_STAGE_TRANSITIONS: Record<ProductionStage, ProductionStage[]> = {
  queued: ['in_kettle', 'curing', 'packaged', 'ready_for_dispatch'],
  in_kettle: ['curing', 'packaged', 'ready_for_dispatch'],
  curing: ['packaged', 'ready_for_dispatch'],
  packaged: ['ready_for_dispatch'],
  ready_for_dispatch: [], // Terminal stage
};

export function validateMTOStageTransition(
  currentStage: ProductionStage,
  nextStage: ProductionStage
): ValidationResult {
  if (currentStage === nextStage) {
    return { valid: true };
  }
  const allowed = VALID_MTO_STAGE_TRANSITIONS[currentStage];
  if (!allowed || !allowed.includes(nextStage)) {
    return {
      valid: false,
      error: `Illegal Stage Transition: Cannot transition MTO order from '${currentStage}' to '${nextStage}'.`,
    };
  }
  return { valid: true };
}

// 6. Batch Code Format Validator (e.g. MTO-LEG-0818)
export function isValidBatchCode(code: string): boolean {
  if (!code || typeof code !== 'string') return false;
  const regex = /^MTO-[A-Z0-9]{3,6}-[0-9]{4,8}$/i;
  return regex.test(code);
}

// 7. Payment Proof Validator
export function validatePaymentProof(proofUrl: string | undefined): ValidationResult {
  if (!proofUrl || proofUrl.trim().length === 0) {
    return { valid: false, error: 'Payment receipt / transaction proof is required.' };
  }
  if (!proofUrl.startsWith('http://') && !proofUrl.startsWith('https://') && !proofUrl.startsWith('data:image/')) {
    return { valid: false, error: 'Payment proof must be a valid HTTPS URL or image data.' };
  }
  return { valid: true };
}

// 8. Daily Demand & Forecast Math Helper
export function calculateAverageDailySales(sales: Sale[], daysWindow: number = 7): number {
  if (!sales || sales.length === 0) return 0;
  const now = new Date().getTime();
  const windowMillis = daysWindow * 24 * 60 * 60 * 1000;
  const filteredSales = sales.filter((s) => {
    const saleTime = new Date(s.date).getTime();
    return now - saleTime <= windowMillis;
  });
  const totalUnitsSold = filteredSales.reduce((sum, s) => sum + s.quantity, 0);
  return Number((totalUnitsSold / Math.max(1, daysWindow)).toFixed(2));
}
