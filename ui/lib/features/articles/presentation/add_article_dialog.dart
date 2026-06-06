import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/features/articles/providers/articles_provider.dart";

class AddArticleDialog extends ConsumerStatefulWidget {
  const AddArticleDialog({super.key});
  @override
  ConsumerState<AddArticleDialog> createState() => _AddArticleDialogState();
}

class _AddArticleDialogState extends ConsumerState<AddArticleDialog> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(articlesProvider.notifier)
          .parseArticle(_urlController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        if (result.queued) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Article will be added when you're back online"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Article"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Enter the URL of an article to add to your library."),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: "Article URL",
                hintText: "https://example.com/article",
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return "Please enter a URL";
                final uri = Uri.tryParse(value.trim());
                if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                  return "Please enter a valid URL";
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Add"),
        ),
      ],
    );
  }
}
