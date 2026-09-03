import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/app_toast.dart';
import '../../data/templates/indian_universities.dart';
import '../providers/app_state_provider.dart';

/// Modern Modal Bottom Sheet for University & College Selection
class UniversitySelectorSheet extends ConsumerStatefulWidget {
  const UniversitySelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UniversitySelectorSheet(),
    );
  }

  @override
  ConsumerState<UniversitySelectorSheet> createState() => _UniversitySelectorSheetState();
}

class _UniversitySelectorSheetState extends ConsumerState<UniversitySelectorSheet> {
  String? _selectedState;
  String _selectedUniversityName = '';
  late String _locationType; // 'CAMPUS' or 'AFFILIATED_COLLEGE'
  late TextEditingController _collegeController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final current = ref.read(selectedUniversityProvider);
    _selectedState = current.state.isNotEmpty && IndianUniversitiesData.statesAndUTs.contains(current.state)
        ? current.state
        : null;
    _selectedUniversityName = current.universityName;
    _locationType = current.locationType;
    _collegeController = TextEditingController(text: current.collegeName ?? '');
  }

  @override
  void dispose() {
    _collegeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _saveUniversity() {
    if (_selectedState == null || _selectedState!.isEmpty) {
      AppToast.error(context, 'Please select your State / UT first');
      return;
    }
    if (_selectedUniversityName.isEmpty) {
      AppToast.error(context, 'Please select a University');
      return;
    }

    ref.read(selectedUniversityProvider.notifier).updateUniversity(
          stateName: _selectedState!,
          universityName: _selectedUniversityName,
          locationType: _locationType,
          collegeName: _locationType == 'AFFILIATED_COLLEGE' && _collegeController.text.trim().isNotEmpty
              ? _collegeController.text.trim()
              : null,
        );
    Navigator.pop(context);
    AppToast.success(context, 'Saved: $_selectedUniversityName');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stateUniversities = _selectedState == null
        ? <UniversityItem>[]
        : IndianUniversitiesData.universities
            .where((u) => u.state == _selectedState)
            .where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'University & College',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STEP 1: STATE
                  Text(
                    'STEP 1: SELECT STATE / UT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStateSelectorTile(isDark),
                  const SizedBox(height: 14),

                  // STEP 2: UNIVERSITY
                  Text(
                    _selectedState != null ? 'STEP 2: SELECT UNIVERSITY IN $_selectedState' : 'STEP 2: SELECT UNIVERSITY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _searchController,
                    enabled: _selectedState != null,
                    style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _selectedState != null ? 'Search University...' : 'Select state above first',
                      hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      filled: true,
                      fillColor: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    constraints: const BoxConstraints(maxHeight: 140),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    child: _selectedState == null
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Please select your state in Step 1.',
                                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              ),
                            ),
                          )
                        : stateUniversities.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'No matching universities found.',
                                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: stateUniversities.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                itemBuilder: (context, index) {
                                  final uni = stateUniversities[index];
                                  final isSel = uni.name == _selectedUniversityName;

                                  return ListTile(
                                    dense: true,
                                    selected: isSel,
                                    selectedTileColor: isDark ? AppColors.cardDark : Colors.white,
                                    title: Text(
                                      uni.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        color: isSel
                                            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                      ),
                                    ),
                                    trailing: isSel
                                        ? const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.presentGreen)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedUniversityName = uni.name;
                                      });
                                    },
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 14),

                  // STEP 3: CAMPUS TYPE
                  Text(
                    'STEP 3: CAMPUS TYPE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildCampusPill(
                        label: 'Main Campus',
                        isSelected: _locationType == 'CAMPUS',
                        isDark: isDark,
                        onTap: () => setState(() => _locationType = 'CAMPUS'),
                      ),
                      const SizedBox(width: 8),
                      _buildCampusPill(
                        label: 'Affiliated College',
                        isSelected: _locationType == 'AFFILIATED_COLLEGE',
                        isDark: isDark,
                        onTap: () => setState(() => _locationType = 'AFFILIATED_COLLEGE'),
                      ),
                    ],
                  ),

                  if (_locationType == 'AFFILIATED_COLLEGE') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _collegeController,
                      style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'College Name',
                        labelStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12),
                        hintText: 'e.g. St. Xavier\'s College',
                        hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 12),
                        filled: true,
                        fillColor: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _saveUniversity,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Save University', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateSelectorTile(bool isDark) {
    return InkWell(
      onTap: () => _openStatePicker(context, isDark),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.map_outlined,
              size: 18,
              color: _selectedState != null
                  ? AppColors.accentIndigoLight
                  : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedState ?? 'Choose State / Union Territory',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _selectedState != null ? FontWeight.w600 : FontWeight.normal,
                  color: _selectedState != null
                      ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                      : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStatePicker(BuildContext context, bool isDark) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
        duration: const Duration(milliseconds: 280),
      ),
      builder: (ctx) => _StatePickerSheet(
        initialState: _selectedState,
        isDark: isDark,
      ),
    );

    if (selected != null && selected != _selectedState) {
      setState(() {
        _selectedState = selected;
        final firstUni = IndianUniversitiesData.universities.firstWhere(
          (u) => u.state == selected,
          orElse: () => IndianUniversitiesData.universities.first,
        );
        _selectedUniversityName = firstUni.name;
        _searchController.clear();
        _searchQuery = '';
      });
    }
  }

  Widget _buildCampusPill({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                  : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sleek modal sheet for searchable, alphabetized State/UT selection
class _StatePickerSheet extends StatefulWidget {
  final String? initialState;
  final bool isDark;

  const _StatePickerSheet({
    required this.initialState,
    required this.isDark,
  });

  @override
  State<_StatePickerSheet> createState() => _StatePickerSheetState();
}

class _StatePickerSheetState extends State<_StatePickerSheet> {
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final allStates = IndianUniversitiesData.statesAndUTs;
    final filteredStates = _filter.trim().isEmpty
        ? allStates
        : allStates.where((s) => s.toLowerCase().contains(_filter.toLowerCase().trim())).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 20,
                    color: AppColors.accentIndigoLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select State / UT',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _filterController,
            autofocus: false,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'Search State or Union Territory...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              suffixIcon: _filter.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _filterController.clear();
                        setState(() => _filter = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
              ),
            ),
            onChanged: (val) => setState(() => _filter = val),
          ),
          const SizedBox(height: 12),

          // Filtered States List
          Flexible(
            child: filteredStates.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No matching state found',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredStates.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final state = filteredStates[index];
                      final isSelected = state == widget.initialState;

                      return InkWell(
                        onTap: () => Navigator.pop(context, state),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  state,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.accentIndigoLight
                                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.accentIndigoLight,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias
typedef UniversitySelectorDialog = UniversitySelectorSheet;
