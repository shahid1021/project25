import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_management/services/ai_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io' show File, Platform;
import 'package:path_provider/path_provider.dart';

class TrendingProject {
  final String title;
  final String description;
  final IconData icon;
  final bool hasAi;
  final int downloads;
  final String? coverImage; // Cover image URL or path

  TrendingProject({
    required this.title,
    required this.description,
    required this.icon,
    required this.hasAi,
    required this.downloads,
    this.coverImage,
  });
}

class TrendingProjectsScreen extends StatefulWidget {
  const TrendingProjectsScreen({super.key});

  @override
  State<TrendingProjectsScreen> createState() => _TrendingProjectsScreenState();
}

class _TrendingProjectsScreenState extends State<TrendingProjectsScreen> {
  bool filterAiOnly = false;

  final List<TrendingProject> projects = [
    TrendingProject(
      title: 'Smart Chat System',
      description:
          'An AI-powered chatbot system using NLP and machine learning to provide intelligent responses. Features include conversation history, sentiment analysis, and multi-language support.',
      icon: Icons.chat_bubble_outline,
      hasAi: true,
      downloads: 1250,
      coverImage: 'assets/images/smart_chat.png', // image here
    ),
    TrendingProject(
      title: 'Data Analytics Dashboard',
      description:
          'Real-time analytics dashboard for visualizing business metrics and KPIs. Includes charts, graphs, and predictive analytics using AI algorithms for trend forecasting.',
      icon: Icons.analytics,
      hasAi: true,
      downloads: 890,
      coverImage: 'assets/images/analytics_dashboard.png', // image here
    ),
    TrendingProject(
      title: 'E-Commerce Platform',
      description:
          'Full-featured e-commerce platform with product catalog, shopping cart, and payment integration. Includes recommendation engine powered by AI.',
      icon: Icons.shopping_cart,
      hasAi: true,
      downloads: 2100,
      coverImage: 'assets/images/ecommerce_platform.png', // image here
    ),
    TrendingProject(
      title: 'Task Management App',
      description:
          'Collaborative task management application for teams. Features include task assignment, deadline tracking, and progress monitoring.',
      icon: Icons.task_alt,
      hasAi: false,
      downloads: 560,
      coverImage: 'assets/images/task_management.png', // image here
    ),
    TrendingProject(
      title: 'Image Recognition System',
      description:
          'Advanced image recognition system using deep learning and CNN models. Can classify and detect objects in images with high accuracy.',
      icon: Icons.image_search,
      hasAi: true,
      downloads: 1850,
      coverImage: 'assets/images/image_recognition.png', // image here
    ),
    TrendingProject(
      title: 'Social Media Network',
      description:
          'Social networking platform with user profiles, feeds, and messaging. Includes content filtering and friend recommendation algorithms.',
      icon: Icons.people,
      hasAi: false,
      downloads: 3400,
      coverImage: 'assets/images/social_network.png', // image here
    ),
    TrendingProject(
      title: 'Voice Assistant',
      description:
          'Voice-activated assistant with speech-to-text and text-to-speech capabilities. Uses AI for natural language understanding and command processing.',
      icon: Icons.mic,
      hasAi: true,
      downloads: 2200,
      coverImage: 'assets/images/voice_assistant.png', // image here
    ),
    TrendingProject(
      title: 'Weather Prediction App',
      description:
          'Weather forecasting application using machine learning models. Provides accurate predictions and severe weather alerts.',
      icon: Icons.cloud,
      hasAi: true,
      downloads: 1600,
      coverImage: 'assets/images/weather_prediction.png', // image here
    ),
  ];

  List<TrendingProject> getFilteredProjects() {
    if (filterAiOnly) {
      return projects.where((p) => p.hasAi).toList();
    }
    return projects;
  }

  void _showProjectDetails(BuildContext context, TrendingProject project) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _ProjectDetailsDialog(project: project);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final filteredProjects = getFilteredProjects();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5A72E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trending Projects',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: height * 0.02,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      filterAiOnly = !filterAiOnly;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          filterAiOnly
                              ? const Color(0xFFE5A72E)
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE5A72E),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.smart_toy, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'AI Only',
                          style: TextStyle(
                            color: filterAiOnly ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                filteredProjects.isEmpty
                    ? Center(
                      child: Text(
                        'No AI projects available',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    )
                    : GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.05,
                        vertical: height * 0.02,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: width * 0.04,
                        mainAxisSpacing: height * 0.02,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        return _buildProjectCard(
                          context,
                          project,
                          width,
                          height,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    TrendingProject project,
    double width,
    double height,
  ) {
    return GestureDetector(
      onTap: () => _showProjectDetails(context, project),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE5A72E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // TOP SECTION - Icon and AI Badge
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: Column(
                children: [
                  Icon(project.icon, color: Colors.white, size: 40),
                  if (project.hasAi) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AI Enabled',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // BOTTOM SECTION - Title and Download Count
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5A72E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.download,
                        size: 12,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${project.downloads} downloads',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDetailsDialog extends StatefulWidget {
  final TrendingProject project;

  const _ProjectDetailsDialog({required this.project});

  @override
  State<_ProjectDetailsDialog> createState() => _ProjectDetailsDialogState();
}

class _ProjectDetailsDialogState extends State<_ProjectDetailsDialog> {
  bool isGenerating = false;
  String? generatedAbstraction;
  final AiService aiService = AiService();

  Future<void> _generateAbstraction() async {
    setState(() {
      isGenerating = true;
    });

    try {
      final prompt =
          'Generate a concise professional abstraction for the following project: ${widget.project.title}. Description: ${widget.project.description}. The abstraction should be 2-3 paragraphs summarizing the key features and benefits.';

      final response = await aiService.sendChatMessage(prompt);

      if (response != null) {
        setState(() {
          generatedAbstraction = response;
          isGenerating = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate abstraction'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        setState(() {
          isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      setState(() {
        isGenerating = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (generatedAbstraction == null || generatedAbstraction!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate abstraction first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${widget.project.title} - Project Abstraction',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Project: ${widget.project.title}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Downloads: ${widget.project.downloads}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                if (widget.project.hasAi)
                  pw.Text(
                    'AI Enabled: Yes',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Abstraction:',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  generatedAbstraction ?? '',
                  style: const pw.TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            '${widget.project.title.replaceAll(' ', '_')}_abstraction.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF ready to download/share'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.project.title,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Cover Image - image here
              if (widget.project.coverImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: Image.asset(
                      widget.project.coverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'image here',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A72E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.project.icon,
                      color: const Color(0xFFE5A72E),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.project.hasAi)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5A72E),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AI Enabled',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (widget.project.hasAi) const SizedBox(height: 4),
                          Text(
                            '${widget.project.downloads} Downloads',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.project.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
              if (generatedAbstraction != null &&
                  generatedAbstraction!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Generated Abstraction',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A72E).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE5A72E).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    generatedAbstraction!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (isGenerating)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE5A72E)),
                )
              else
                Row(
                  children: [
                    if (generatedAbstraction == null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _generateAbstraction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5A72E),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Generate Abstraction',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _generateAbstraction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5A72E),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Regenerate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (generatedAbstraction != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _downloadPdf,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFE5A72E),
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Download PDF',
                            style: TextStyle(
                              color: Color(0xFFE5A72E),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
