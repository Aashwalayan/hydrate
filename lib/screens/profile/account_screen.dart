import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    this.initialName = 'User',
    this.email = 'your@email.com',
    this.onNameChanged,
    this.onChangePassword,
    this.onDeleteAccount,
  });

  final String initialName;
  final String email;
  final Future<void> Function(String name)? onNameChanged;
  final Future<void> Function(String currentPassword, String newPassword)?
  onChangePassword;
  final VoidCallback? onDeleteAccount;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late String _name;
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName;
  }

  Future<void> _showChangePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final current = currentController.text;
                    final newPassword = newController.text;
                    final confirm = confirmController.text;

                    if (current.isEmpty ||
                        newPassword.isEmpty ||
                        confirm.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields.'),
                        ),
                      );
                      return;
                    }

                    if (newPassword != confirm) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('New passwords do not match.'),
                        ),
                      );
                      return;
                    }

                    if (newPassword.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password must be at least 6 characters.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop({
                      'currentPassword': current,
                      'newPassword': newPassword,
                    });
                  },
                  child: const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );


    if (result == null || !mounted) return;

    try {
      await widget.onChangePassword?.call(
        result['currentPassword']!,
        result['newPassword']!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Change name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              counterText: '',
              filled: true,
              fillColor: colors.onSurface.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName == _name || !mounted) return;

    if (widget.onNameChanged == null) {
      setState(() => _name = newName);
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await widget.onNameChanged!(newName);
      if (!mounted) return;
      setState(() {
        _name = newName;
        _isSavingName = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name updated.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSavingName = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your name.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This will permanently delete your Hydrate account and its data. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    if (widget.onDeleteAccount != null) {
      widget.onDeleteAccount!();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deletion is not available yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final primary = colors.primary;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _topBar(context),
                  const SizedBox(height: 28),
                  _header(context, primary),
                  const SizedBox(height: 32),
                  _sectionLabel(context, 'YOUR ACCOUNT'),
                  const SizedBox(height: 10),
                  _accountCard(context, primary),
                  const SizedBox(height: 28),
                  _sectionLabel(context, 'SECURITY'),
                  const SizedBox(height: 10),
                  _securityCard(context, primary),
                  const SizedBox(height: 28),
                  _sectionLabel(context, 'DANGER ZONE'),
                  const SizedBox(height: 10),
                  _dangerCard(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Material(
          color: colors.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back_rounded),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, Color primary) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.person_outline_rounded, color: primary, size: 27),
        ),
        const SizedBox(height: 18),
        Text(
          'Account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage your account information and security.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: colors.onSurface.withValues(alpha: 0.48),
        ),
      ),
    );
  }

  Widget _accountCard(BuildContext context, Color primary) {
    return _card(
      context,
      child: Column(
        children: [
          _row(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Name',
            subtitle: _name,
            primary: primary,
            trailing: _isSavingName
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap: _isSavingName ? null : _editName,
          ),
          _divider(context),
          _row(
            context,
            icon: Icons.mail_outline_rounded,
            title: 'Email',
            subtitle: widget.email,
            primary: primary,
            trailing: Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _securityCard(BuildContext context, Color primary) {
    return _card(
      context,
      child: _row(
        context,
        icon: Icons.lock_outline_rounded,
        title: 'Change password',
        subtitle: 'Update your account password',
        primary: primary,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _showChangePasswordDialog,
      ),
    );
  }

  Widget _dangerCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.error.withValues(alpha: 0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _deleteAccount,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 21,
                    color: colors.error,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Delete account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.error,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.error.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primary,
    required Widget trailing,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              _iconBox(context, icon, primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconTheme(
                data: IconThemeData(
                  size: 20,
                  color: colors.onSurface.withValues(alpha: 0.3),
                ),
                child: trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(BuildContext context, IconData icon, Color primary) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 21, color: primary),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }
}
