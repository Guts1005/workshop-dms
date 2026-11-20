import 'gst_engine.dart';

class InvoiceWorkspace {
  const InvoiceWorkspace({
    required this.jobCardId,
    required this.registrationNumber,
    required this.workshopName,
    required this.customerName,
    required this.items,
    required this.existingInvoice,
    this.savedSupplierAddress,
    this.savedSupplierGstin,
    this.savedSupplierStateCode,
    this.savedRecipientAddress,
    this.savedRecipientGstin,
    this.savedPlaceOfSupplyStateCode,
  });

  final String jobCardId;
  final String registrationNumber;
  final String workshopName;
  final String customerName;
  final List<InvoiceLineItem> items;
  final IssuedInvoice? existingInvoice;
  final String? savedSupplierAddress;
  final String? savedSupplierGstin;
  final String? savedSupplierStateCode;
  final String? savedRecipientAddress;
  final String? savedRecipientGstin;
  final String? savedPlaceOfSupplyStateCode;
}

class InvoiceIssueDetails {
  const InvoiceIssueDetails({
    required this.supplierName,
    required this.supplierAddress,
    required this.supplierGstin,
    required this.supplierStateCode,
    required this.recipientAddress,
    required this.recipientGstin,
    required this.placeOfSupplyStateCode,
  });

  final String supplierName;
  final String supplierAddress;
  final String supplierGstin;
  final String supplierStateCode;
  final String recipientAddress;
  final String recipientGstin;
  final String placeOfSupplyStateCode;
}

class InvoiceSnapshotLine {
  const InvoiceSnapshotLine({
    required this.description,
    required this.code,
    required this.itemType,
    required this.quantity,
    required this.unitRatePaise,
    required this.gstRatePercent,
    required this.taxablePaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.igstPaise,
    required this.totalPaise,
  });

  final String description;
  final String code;
  final String itemType;
  final num quantity;
  final int unitRatePaise;
  final num gstRatePercent;
  final int taxablePaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;
  final int totalPaise;
}

class IssuedInvoice {
  const IssuedInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.issueDate,
    required this.supplierName,
    required this.supplierAddress,
    required this.supplierGstin,
    required this.supplierStateCode,
    required this.recipientName,
    required this.recipientAddress,
    required this.recipientGstin,
    required this.placeOfSupplyStateCode,
    required this.taxType,
    required this.totalTaxablePaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.igstPaise,
    required this.totalTaxPaise,
    required this.grandTotalPaise,
    required this.lines,
  });

  final String id;
  final String invoiceNumber;
  final DateTime issueDate;
  final String supplierName;
  final String supplierAddress;
  final String supplierGstin;
  final String supplierStateCode;
  final String recipientName;
  final String recipientAddress;
  final String? recipientGstin;
  final String placeOfSupplyStateCode;
  final String taxType;
  final int totalTaxablePaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;
  final int totalTaxPaise;
  final int grandTotalPaise;
  final List<InvoiceSnapshotLine> lines;

  bool get intraState => taxType == 'INTRA_STATE';
}
