import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/survey.dart';
import '../../providers/surveys_provider.dart';

class SurveysScreen extends ConsumerWidget {
  const SurveysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(surveysProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encuestas'),
        actions: [
          if (state.pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(
                  '${state.pendingCount} pendiente${state.pendingCount != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: colors.primaryContainer,
                labelStyle: TextStyle(color: colors.onPrimaryContainer),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
      body: state.isLoading && state.surveys.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(surveysProvider.notifier).refresh(),
              child: state.surveys.isEmpty
                  ? _EmptyState(error: state.error)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.surveys.length,
                      itemBuilder: (context, i) {
                        final survey = state.surveys[i];
                        final hasResponded =
                            state.respondedIds.contains(survey.id);
                        return _SurveyCard(
                          survey: survey,
                          hasResponded: hasResponded,
                        );
                      },
                    ),
            ),
    );
  }
}

// ── Tarjeta de encuesta ────────────────────────────────────────────────────────

class _SurveyCard extends ConsumerWidget {
  const _SurveyCard({required this.survey, required this.hasResponded});

  final Survey survey;
  final bool hasResponded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final canAnswer = survey.isActive && !hasResponded;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: título + badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    survey.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  status: hasResponded ? 'responded' : survey.status,
                ),
              ],
            ),

            // Descripción
            if (survey.description != null && survey.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  survey.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ),

            const SizedBox(height: 10),

            // Metadatos
            Wrap(
              spacing: 12,
              children: [
                if (survey.isAnonymous)
                  _MetaChip(Icons.visibility_off_outlined, 'Anónima'),
                if (survey.closesAtDate != null)
                  _MetaChip(
                    Icons.schedule_outlined,
                    'Cierra ${DateFormat('d MMM', 'es').format(survey.closesAtDate!)}',
                  ),
              ],
            ),

            // Botón de acción
            if (survey.isActive) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: canAnswer
                    ? FilledButton.icon(
                        icon: const Icon(Icons.edit_note_outlined, size: 18),
                        label: const Text('Responder encuesta'),
                        onPressed: () =>
                            context.push('/surveys/${survey.id}'),
                      )
                    : OutlinedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Ya respondiste'),
                        onPressed: null,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Badges y chips ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'responded' => ('Respondida', const Color(0xFF059669)),
      'active' => ('Activa', const Color(0xFF4F46E5)),
      'closed' => ('Cerrada', const Color(0xFF64748B)),
      _ => ('Borrador', const Color(0xFF9CA3AF)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                error != null
                    ? Icons.cloud_off_outlined
                    : Icons.poll_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                error ?? 'No hay encuestas activas',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Desliza para reintentar',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
