import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/job_provider.dart';
import '../services/job_service.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  final _searchCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().fetchJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Discovery"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchJobs(),
          )
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ShadInput(
                  controller: _searchCtrl,
                  placeholder: const Text("Search job titles, skills..."),
                  trailing: ShadButton.ghost(
                    onPressed: () => provider.updateFilters(query: _searchCtrl.text),
                    child: const Icon(Icons.search),
                  ),
                  onSubmitted: (v) => provider.updateFilters(query: v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ShadInput(
                        controller: _locationCtrl,
                        placeholder: const Text("Location"),
                        onSubmitted: (v) => provider.updateFilters(location: v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ShadInput(
                        controller: _salaryCtrl,
                        placeholder: const Text("Min Salary (\$)"),
                        keyboardType: TextInputType.number,
                        onSubmitted: (v) => provider.updateFilters(minSalary: int.tryParse(v)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Sort by:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: provider.jobs.isEmpty ? 'newest' : null, // Simplification
                      underline: const SizedBox(),
                      hint: const Text("Newest"),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text("Newest")),
                        DropdownMenuItem(value: 'salary', child: Text("Highest Salary")),
                      ],
                      onChanged: (v) => provider.updateFilters(sortBy: v),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Loading or Results
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.jobs.isEmpty
                    ? const Center(child: Text("No jobs found matching your criteria."))
                    : ListView.builder(
                        itemCount: provider.jobs.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final job = provider.jobs[index];
                          return _JobCard(job: job);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final dynamic job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();
    final score = provider.getScore(job['id']);

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => context.push('/jobs/${job['id']}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job['title'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (provider.hasCV) 
                  _buildMatchBadge(provider, score),
              ],
            ),
            const SizedBox(height: 4),
            Text(job['company'] ?? 'Unknown Company', style: TextStyle(color: Colors.blueGrey[300])),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(job['location'] ?? 'N/A'),
                const Spacer(),
                const Icon(Icons.attach_money, size: 16, color: Colors.greenAccent),
                Text(job['salary'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchBadge(JobProvider provider, double? score) {
    if (score != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
        ),
        child: Text(
          "${score.toInt()}% Match",
          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }

    if (provider.isMatching) {
      return const SizedBox(
        width: 60,
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    return const SizedBox.shrink();
  }
}
