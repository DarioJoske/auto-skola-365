import 'package:flutter/material.dart';
import '../../design_system.dart';

/// An interactive, in-memory example without application dependencies.
final class AdminDesignSystemExample extends StatefulWidget {
  const AdminDesignSystemExample({super.key});
  @override
  State<AdminDesignSystemExample> createState() => _AdminExampleState();
}

class _AdminExampleState extends State<AdminDesignSystemExample> {
  final _form = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Admin · pregled komponenti',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: AppSpacing.lg),
      const AppStatCard(
        label: 'Aktivni kandidati',
        value: '128',
        detail: 'Pokazni podaci · rujan 2026.',
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Ime i prezime',
                initialValue: 'Ana Horvat',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Unesite ime kandidata.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              const AppTextField(
                label: 'E-mail adresa',
                initialValue: 'ana@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: 'Spremi',
                    loadingLabel: 'Spremanje…',
                    isLoading: _isSaving,
                    onPressed: () {
                      if (_form.currentState!.validate()) {
                        setState(() {
                          _isSaving = true;
                          _hasError = false;
                        });
                      }
                    },
                  ),
                  AppButton(
                    label: 'Prikaži grešku',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => setState(() {
                      _isSaving = false;
                      _hasError = true;
                    }),
                  ),
                  const AppButton(label: 'Nedostupna radnja', onPressed: null),
                ],
              ),
            ],
          ),
        ),
      ),
      if (_hasError) ...[
        const SizedBox(height: AppSpacing.md),
        AppNotice(
          title: 'Spremanje nije uspjelo',
          message: 'Pokazna greška. Uneseni podaci ostaju sačuvani.',
          tone: AppTone.error,
          action: AppButton(
            label: 'Pokušaj ponovno',
            variant: AppButtonVariant.text,
            onPressed: () => setState(() {
              _hasError = false;
              _isSaving = true;
            }),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      AppHorizontalScroll(
        child: DataTable(
          dataRowMinHeight: 64,
          dataRowMaxHeight: double.infinity,
          columns: const [
            DataColumn(label: Text('Kandidat')),
            DataColumn(label: Text('Sati')),
            DataColumn(label: Text('Status')),
          ],
          rows: const [
            DataRow(
              cells: [
                DataCell(Text('Ana Horvat')),
                DataCell(Text('25 / 35')),
                DataCell(AppStatusBadge(label: 'U vožnji')),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
