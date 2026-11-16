import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/models.dart';

const ink = Color(0xFF253A36),
    accent = Color(0xFF8B5E3C),
    moss = Color(0xFF367565);

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.trailing});
  final String title, subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        ?trailing,
      ],
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = 24});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.message, {super.key, this.error = false, this.onRetry});
  final String message;
  final bool error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: error
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(error ? Icons.error_outline : Icons.info_outline, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

class ApiView<T> extends StatelessWidget {
  const ApiView({
    super.key,
    required this.future,
    required this.builder,
    this.onRetry,
  });
  final Future<T> future;
  final Widget Function(T) builder;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Notice(snapshot.error.toString(), error: true, onRetry: onRetry);
      }
      return builder(snapshot.data as T);
    },
  );
}

class FormGrid extends StatelessWidget {
  const FormGrid({super.key, required this.children, this.minWidth = 220});
  final List<Widget> children;
  final double minWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = (box.maxWidth / (minWidth + 16)).floor().clamp(1, 4);
      final width = (box.maxWidth - (cols - 1) * 16) / cols;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: children
            .map((c) => SizedBox(width: width, child: c))
            .toList(),
      );
    },
  );
}

class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label, value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    key: ValueKey('$label:$value'),
    initialValue: options.containsKey(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: options.entries
        .map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '출발일',
  });
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String label;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    ),
    icon: const Icon(Icons.calendar_today_outlined, size: 18),
    label: Text('$label  ${dateLabel(value)}'),
    onPressed: () async {
      final now = DateUtils.dateOnly(DateTime.now());
      final date = await showDatePicker(
        context: context,
        initialDate: value.isBefore(now) ? now : value,
        firstDate: now,
        lastDate: now.add(const Duration(days: 730)),
        locale: const Locale('ko'),
      );
      if (date != null) onChanged(date);
    },
  );
}

void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Future<void> openLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !['http', 'https', 'tel'].contains(uri.scheme)) return;
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
      context.mounted) {
    toast(context, '링크를 열지 못했어요.');
  }
}

class Stat extends StatelessWidget {
  const Stat(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 140,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    ),
  );
}
