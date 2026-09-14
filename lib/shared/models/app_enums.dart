import '../../core/constants/app_strings.dart';

enum FurnishingType { unfurnished, partiallyFurnished, fullyFurnished }

extension FurnishingTypeX on FurnishingType {
  String get databaseValue => switch (this) {
    FurnishingType.unfurnished => 'UNFURNISHED',
    FurnishingType.partiallyFurnished => 'PARTIALLY_FURNISHED',
    FurnishingType.fullyFurnished => 'FULLY_FURNISHED',
  };

  String get label => switch (this) {
    FurnishingType.unfurnished => AppStrings.unfurnished,
    FurnishingType.partiallyFurnished => AppStrings.partiallyFurnished,
    FurnishingType.fullyFurnished => AppStrings.fullyFurnished,
  };

  static FurnishingType fromDatabase(String value) => switch (value) {
    'PARTIALLY_FURNISHED' => FurnishingType.partiallyFurnished,
    'FULLY_FURNISHED' => FurnishingType.fullyFurnished,
    _ => FurnishingType.unfurnished,
  };
}

enum InspectionType { moveIn, moveOut }

extension InspectionTypeX on InspectionType {
  String get databaseValue => switch (this) {
    InspectionType.moveIn => 'MOVE_IN',
    InspectionType.moveOut => 'MOVE_OUT',
  };

  String get label => switch (this) {
    InspectionType.moveIn => AppStrings.moveInInspection,
    InspectionType.moveOut => AppStrings.moveOutInspection,
  };

  static InspectionType fromDatabase(String value) =>
      value == 'MOVE_OUT' ? InspectionType.moveOut : InspectionType.moveIn;
}

enum InspectionCondition { good, minorDamage, damaged, missing, notApplicable }

extension InspectionConditionX on InspectionCondition {
  String get databaseValue => switch (this) {
    InspectionCondition.good => 'GOOD',
    InspectionCondition.minorDamage => 'MINOR_DAMAGE',
    InspectionCondition.damaged => 'DAMAGED',
    InspectionCondition.missing => 'MISSING',
    InspectionCondition.notApplicable => 'NOT_APPLICABLE',
  };

  String get label => switch (this) {
    InspectionCondition.good => AppStrings.conditionGood,
    InspectionCondition.minorDamage => AppStrings.conditionMinorDamage,
    InspectionCondition.damaged => AppStrings.conditionDamaged,
    InspectionCondition.missing => AppStrings.conditionMissing,
    InspectionCondition.notApplicable => AppStrings.conditionNotApplicable,
  };

  static InspectionCondition fromDatabase(String value) => switch (value) {
    'MINOR_DAMAGE' => InspectionCondition.minorDamage,
    'DAMAGED' => InspectionCondition.damaged,
    'MISSING' => InspectionCondition.missing,
    'NOT_APPLICABLE' => InspectionCondition.notApplicable,
    _ => InspectionCondition.good,
  };
}

enum PhotoUploadStatus { pending, uploading, uploaded, failed }

extension PhotoUploadStatusX on PhotoUploadStatus {
  String get databaseValue => switch (this) {
    PhotoUploadStatus.pending => 'PENDING',
    PhotoUploadStatus.uploading => 'UPLOADING',
    PhotoUploadStatus.uploaded => 'UPLOADED',
    PhotoUploadStatus.failed => 'FAILED',
  };

  String get label => switch (this) {
    PhotoUploadStatus.uploading => AppStrings.uploadSending,
    PhotoUploadStatus.uploaded => AppStrings.uploadSent,
    PhotoUploadStatus.pending ||
    PhotoUploadStatus.failed => AppStrings.uploadNotSent,
  };

  static PhotoUploadStatus fromDatabase(String value) => switch (value) {
    'UPLOADING' => PhotoUploadStatus.uploading,
    'UPLOADED' => PhotoUploadStatus.uploaded,
    'FAILED' => PhotoUploadStatus.failed,
    _ => PhotoUploadStatus.pending,
  };
}

enum InspectionStatus {
  draft,
  reviewRequired,
  revisionRequested,
  approved,
  partiallyConfirmed,
  finalized,
}

extension InspectionStatusX on InspectionStatus {
  String get databaseValue => switch (this) {
    InspectionStatus.draft => 'DRAFT',
    InspectionStatus.reviewRequired => 'REVIEW_REQUIRED',
    InspectionStatus.revisionRequested => 'REVISION_REQUESTED',
    InspectionStatus.approved => 'APPROVED',
    InspectionStatus.partiallyConfirmed => 'PARTIALLY_CONFIRMED',
    InspectionStatus.finalized => 'FINALIZED',
  };

  String get label => switch (this) {
    InspectionStatus.draft => AppStrings.statusDraft,
    InspectionStatus.reviewRequired => AppStrings.statusReviewRequired,
    InspectionStatus.revisionRequested => AppStrings.statusRevisionRequested,
    InspectionStatus.approved => AppStrings.statusApproved,
    InspectionStatus.partiallyConfirmed => AppStrings.statusPartiallyConfirmed,
    InspectionStatus.finalized => AppStrings.statusFinalized,
  };

  static InspectionStatus fromDatabase(String value) => switch (value) {
    'REVIEW_REQUIRED' => InspectionStatus.reviewRequired,
    'REVISION_REQUESTED' => InspectionStatus.revisionRequested,
    'APPROVED' => InspectionStatus.approved,
    'PARTIALLY_CONFIRMED' => InspectionStatus.partiallyConfirmed,
    'FINALIZED' => InspectionStatus.finalized,
    _ => InspectionStatus.draft,
  };
}

enum FillMethod { self, tenant }

extension FillMethodX on FillMethod {
  String get databaseValue => this == FillMethod.tenant ? 'TENANT' : 'SELF';
  String get label => this == FillMethod.tenant
      ? AppStrings.tenantFills
      : AppStrings.fillMyself;

  static FillMethod fromDatabase(String value) =>
      value == 'TENANT' ? FillMethod.tenant : FillMethod.self;
}

enum ComparisonResult { unchanged, newDamage, improved, missing, notComparable }

extension ComparisonResultX on ComparisonResult {
  String get databaseValue => switch (this) {
    ComparisonResult.unchanged => 'UNCHANGED',
    ComparisonResult.newDamage => 'NEW_DAMAGE',
    ComparisonResult.improved => 'IMPROVED',
    ComparisonResult.missing => 'MISSING',
    ComparisonResult.notComparable => 'NOT_COMPARABLE',
  };

  String get label => switch (this) {
    ComparisonResult.unchanged => AppStrings.comparisonUnchanged,
    ComparisonResult.newDamage => AppStrings.comparisonNewDamage,
    ComparisonResult.improved => AppStrings.comparisonImproved,
    ComparisonResult.missing => AppStrings.comparisonMissing,
    ComparisonResult.notComparable => AppStrings.comparisonNotComparable,
  };
}

enum FeedbackCategory { idea, bug, inspection, billing, help, other }

extension FeedbackCategoryX on FeedbackCategory {
  String get databaseValue => switch (this) {
    FeedbackCategory.idea => 'IDEA',
    FeedbackCategory.bug => 'BUG',
    FeedbackCategory.inspection => 'INSPECTION_ACT',
    FeedbackCategory.billing => 'BILLING',
    FeedbackCategory.help => 'HELP',
    FeedbackCategory.other => 'OTHER',
  };

  String get label => switch (this) {
    FeedbackCategory.idea => AppStrings.feedbackNewIdea,
    FeedbackCategory.bug => AppStrings.feedbackBug,
    FeedbackCategory.inspection => AppStrings.feedbackInspection,
    FeedbackCategory.billing => AppStrings.feedbackBilling,
    FeedbackCategory.help => AppStrings.feedbackHelp,
    FeedbackCategory.other => AppStrings.feedbackOther,
  };
}
