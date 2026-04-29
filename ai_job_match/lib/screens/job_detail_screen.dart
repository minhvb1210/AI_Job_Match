import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/job_provider.dart';
import '../services/job_service.dart';

class JobDetailScreen extends StatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _jobService = JobService();
  Map<String, dynamic>? _job;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _jobService.getJobById(widget.jobId);
      setState(() {
        _job = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();
    final score = provider.getScore(widget.jobId);

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_job == null) return const Scaffold(body: Center(child: Text("Error loading job details.")));

    return Scaffold(
      appBar: AppBar(
        title: Text(_job!['title']),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ShadButton(
                  child: const Text("Apply Now"),
                  onPressed: () {
                    ShadToaster.of(context).show(const ShadToast(title: Text("Feature Coming Soon"), description: Text("Application submission will be enabled in the next update.")));
                  },
                ),
              ),
              const SizedBox(width: 8),
              ShadButton.outline(
                child: const Icon(Icons.bookmark_border),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_job!['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_job!['company'] ?? 'Unknown Company', style: const TextStyle(fontSize: 18, color: Colors.blueAccent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Score Insight
            if (score != null) ...[
               _buildInsightCard(context, score),
               const SizedBox(height: 24),
            ],

            // Content
            _Section(title: "Location", content: _job!['location'] ?? 'N/A'),
            _Section(title: "Salary", content: _job!['salary'] ?? 'N/A'),
            _Section(title: "Job Type", content: _job!['job_type'] ?? 'Not specified'),
            _Section(title: "Description", content: _job!['description']),
            _Section(title: "Required Skills", content: _job!['skills']),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, double score) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.blueAccent),
              const SizedBox(width: 8),
              const Text("AI Match Score", style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text("${score.toInt()}%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 12),
          ShadButton.ghost(
            child: const Text("View Match Detail"),
            onPressed: () => context.push('/explain/${widget.jobId}', extra: _job!['title']),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}
