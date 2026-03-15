abstract class RouteNames {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const privacy = '/privacy';
  static const loginOrCreate = '/login';
  static const pin = '/pin';

  // Bénéficiaire
  static const beneficiaryIntro = '/beneficiary/intro';
  static const beneficiaryEvaluation = '/beneficiary/evaluation';
  static const beneficiaryHome = '/beneficiary';
  static const beneficiaryBilans = '/beneficiary/bilans';
  static const beneficiaryReportDetail = '/beneficiary/reports/:id';
  static const beneficiaryDepistage = '/beneficiary/depistage';
  static const beneficiaryConseiller = '/beneficiary/conseiller';
  static const beneficiaryQr = '/beneficiary/qr';

  // Ambassador
  static const ambassadorHome = '/ambassador';
  static const ambassadorQr = '/ambassador/qr';
  static const ambassadorDepistage = '/ambassador/depistage';
  static const ambassadorConseiller = '/ambassador/conseiller';

  // Field Agent
  static const fieldAgentHome         = '/field-agent';
  static const fieldAgentQr           = '/field-agent/qr';
  static const fieldAgentAssistedEval = '/field-agent/assisted-eval';
}
