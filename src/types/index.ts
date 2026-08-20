// Data Models for VertexIS - Marsh Bites Branch Management System

export type UserRole = 'admin' | 'branch';

export interface UserModel {
  id: string;
  name: string;
  email: string;
  password: string;
  role: UserRole;
  branchId?: string;
}

export type BranchStatus = 'Active' | 'Pending Activation' | 'Suspended' | 'Inactive' | 'Closed';

export type BranchBusinessType =
  | 'Franchise Kiosk'
  | 'Mall Inline Store'
  | 'Full Dine-In Branch'
  | 'Food Hall Booth'
  | 'Express Counter';

export interface Branch {
  id: string;
  name: string;
  code: string;
  businessType: BranchBusinessType | string;
  location: string;
  contactNumber: string;
  email: string;
  operatingHours: string;
  status: BranchStatus;
  managerName?: string;
  managerPhone?: string;
  managerEmail?: string;
  managerGovId?: string;
  applicationId?: string;
  createdAt: string;
  updatedAt?: string;
  closedAt?: string;
  archivedAt?: string;
  suspensionReason?: string;
}

export type DocumentType =
  | 'business_permit'
  | 'dti_registration'
  | 'bir_registration'
  | 'mayors_permit'
  | 'government_id'
  | 'lease_contract'
  | 'other';

export type DocumentVerificationStatus = 'pending' | 'verified' | 'rejected' | 'resubmission_requested';

export interface BranchDocument {
  id: string;
  branchId?: string;
  applicationId?: string;
  documentType: DocumentType;
  title: string;
  fileUrl: string;
  fileName: string;
  fileSize: string;
  fileType: string;
  status: DocumentVerificationStatus;
  remarks?: string;
  uploadedAt: string;
  verifiedAt?: string;
  verifiedBy?: string;
}

export type ApplicationStatus =
  | 'Pending Review'
  | 'Under Verification'
  | 'Approved'
  | 'Rejected'
  | 'Requires Revision';

export interface BranchApplication {
  id: string;
  branchName: string;
  branchCode: string;
  businessType: BranchBusinessType | string;
  address: string;
  contactNumber: string;
  email: string;
  operatingHours: string;
  managerName: string;
  managerPhone: string;
  managerEmail: string;
  managerGovId: string;
  documents: BranchDocument[];
  status: ApplicationStatus;
  reviewNotes?: string;
  rejectionReason?: string;
  revisionRemarks?: string;
  submittedAt: string;
  updatedAt: string;
  reviewedAt?: string;
  reviewedBy?: string;
  approvedBranchId?: string;
}

export type BranchAccountRole = 'Branch Manager' | 'Staff' | 'Cashier' | 'Inventory Specialist';

export interface BranchAccount {
  id: string;
  branchId: string;
  branchName: string;
  username: string;
  temporaryPassword: string;
  fullName: string;
  email: string;
  phone?: string;
  role: BranchAccountRole;
  permissions: string[];
  isActive: boolean;
  credentialsSent: boolean;
  credentialsSentAt?: string;
  createdAt: string;
  lastLoginAt?: string;
}

export interface BranchStatusHistory {
  id: string;
  branchId: string;
  branchName: string;
  previousStatus: BranchStatus;
  newStatus: BranchStatus;
  reason: string;
  changedBy: string;
  timestamp: string;
}

export interface BranchAuditLog {
  id: string;
  branchId?: string;
  branchName?: string;
  action: string;
  user: string;
  timestamp: string;
  remarks: string;
  metadata?: Record<string, any>;
}

export interface Product {
  id: string;
  name: string;
  flavor: string;
  price: number;
  adminStock: number;
}

export interface OrderItem {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
}

export type OrderStatus = 'pending' | 'waitingApproval' | 'approved' | 'rejected';
export type ProductionStage = 'queued' | 'in_kettle' | 'curing' | 'packaged' | 'ready_for_dispatch';

export interface Order {
  id: string;
  branchId: string;
  branchName: string;
  status: OrderStatus;
  productionStage?: ProductionStage;
  batchCode?: string;
  estimatedReadyDate?: string;
  totalAmount: number;
  createdAt: string; // ISO string
  items: OrderItem[];
  proofImagePath?: string;
  rejectionReason?: string;
}

export type BatchStage = 'in_kettle' | 'curing' | 'packaged' | 'completed';

export interface ProductionBatch {
  id: string;
  batchCode: string;
  productId: string;
  productFlavor: string;
  quantity: number;
  targetOrderId?: string;
  targetBranchName?: string;
  stage: BatchStage;
  chefName: string;
  startedAt: string;
  completedAt?: string;
  notes?: string;
}

export type PaymentStatus = 'pending' | 'approved' | 'rejected';

export interface Payment {
  id: string;
  orderId: string;
  branchId: string;
  proofImagePath: string;
  status: PaymentStatus;
}

export type DeliveryStatus = 'pending' | 'inTransit' | 'delivered' | 'canceled';

export interface Delivery {
  id: string;
  orderId: string;
  branchId: string;
  address: string;
  status: DeliveryStatus;
  scheduledAt: string;
  deliveredAt?: string;
  courierName?: string;
  trackingNumber?: string;
  notes?: string;
}

export type ReceivingStatus = 'pending' | 'received' | 'damaged' | 'returned';

export interface Receiving {
  id: string;
  deliveryId: string;
  orderId: string;
  branchId: string;
  status: ReceivingStatus;
  createdAt: string;
  receivedAt?: string;
  receiverName?: string;
  conditionNotes?: string;
  notes?: string;
}

export interface InventoryItem {
  id: string;
  branchId: string;
  productId: string;
  productName: string;
  stock: number;
}

export interface RestockSuggestion {
  productId: string;
  productName: string;
  currentStock: number;
  averageDailyQuantity: number;
  expectedWeeklyDemand: number;
  suggestedOrderQuantity: number;
  urgency: 'Urgent' | 'Review' | 'Monitor';
}

export interface Sale {
  id: string;
  branchId: string;
  productId: string;
  productName: string;
  quantity: number;
  total: number;
  date: string;
  receiptPath?: string;
  paymentMethod?: 'Cash' | 'GCash' | 'Maya' | 'Card' | 'Zobaze POS' | string;
  amountTendered?: number;
  change?: number;
  discountAmount?: number;
  discountType?: string;
  customerName?: string;
  cashierName?: string;
  source?: 'VertexIS POS' | 'Zobaze POS Sync' | string;
}

export interface Announcement {
  id: string;
  title: string;
  message: string;
  createdAt: string;
}

export type CalendarEventType = 'task' | 'appointment';

export interface CalendarEvent {
  id: string;
  title: string;
  date: string;
  description: string;
  type: CalendarEventType;
  branchId?: string;
  branchName?: string;
}
