import 'package:flutter/widgets.dart';

abstract class OtpLoginEvent {
  const OtpLoginEvent();
}

class OtpEmailChanged extends OtpLoginEvent {
  final String email;
  const OtpEmailChanged(this.email);
}

class OtpRequestSubmitted extends OtpLoginEvent {
  const OtpRequestSubmitted();
}

class OtpCodeChanged extends OtpLoginEvent {
  final String code;
  const OtpCodeChanged(this.code);
}

class OtpVerifySubmitted extends OtpLoginEvent {
  final BuildContext context;
  const OtpVerifySubmitted(this.context);
}

class OtpEditEmailPressed extends OtpLoginEvent {
  const OtpEditEmailPressed();
}

class OtpResendRequested extends OtpLoginEvent {
  const OtpResendRequested();
}

// ⬇️ NEW: internal cooldown events
class OtpCooldownTick extends OtpLoginEvent {
  const OtpCooldownTick();
}

class OtpCooldownFinished extends OtpLoginEvent {
  const OtpCooldownFinished();
}
