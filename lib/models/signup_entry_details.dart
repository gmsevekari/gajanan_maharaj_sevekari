/// The details of a sign-up entry that the edit dialog collects and that a
/// devotee or admin can change later. Text is trimmed and a blank phone,
/// email or note is null.
class SignupEntryDetails {
  final String name;
  final String? phone;
  final String? email;
  final double? pledgeAmount;
  final String? note;

  const SignupEntryDetails({
    required this.name,
    this.phone,
    this.email,
    this.pledgeAmount,
    this.note,
  });
}
