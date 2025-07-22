import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'package:vayujal_technician/pages/videoPlayerHelper.dart';


class ServiceDetailScreen extends StatefulWidget {
  final String srNumber;

  const ServiceDetailScreen({super.key, required this.srNumber});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  Map<String, dynamic>? serviceDetail;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServiceDetail(); // Call the async method without awaiting
  }

  // Separate method to handle async operations
  Future<void> _loadServiceDetail() async {
    serviceDetail = await _fetchServiceDetail();
  }

  Future<Map<String, dynamic>?> _fetchServiceDetail() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('serviceHistory')
          .doc(widget.srNumber)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        setState(() {
          isLoading = false;
        });
        return data;
      } else {
        setState(() {
          isLoading = false;
        });
        return null;
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching service details: $e';
        isLoading = false;
      });
      return null;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'N/A';
      }
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'N/A';
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildDetailCard(String title, Widget content) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipList(String label, dynamic items) {
    List<dynamic> itemList = [];

    if (items == null) {
      return _buildDetailRow(label, 'None');
    } else if (items is List) {
      itemList = items;
    } else if (items is String) {
      if (items.isNotEmpty) {
        itemList = [items];
      }
    } else {
      itemList = [items.toString()];
    }

    if (itemList.isEmpty) {
      return _buildDetailRow(label, 'None');
    }

    String itemText = itemList.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            itemText,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget buildLabeledContent({
    required String content,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceExecutionDetails() {
    if (serviceDetail == null) {
      return const SizedBox.shrink();
    }

    return _buildDetailCard(
      'Service Execution Details',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Status', (serviceDetail!['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase()),
          _buildDetailRow('Complaint \nRelated To', serviceDetail!['complaintRelatedTo'] ?? ''),
          _buildDetailRow('Type of Issue Raised', serviceDetail!['typeOfRaisedIssue'] ?? ''),
          _buildDetailRow('Issue Type', serviceDetail!['issueType'] ?? ''),
          const SizedBox(height: 8),
          _buildChipList('Issue Identification', serviceDetail!['issueIdentification']),
          _buildChipList('Parts Replaced', serviceDetail!['partsReplaced']),
        ],
      ),
    );
  }

  Widget _buildTechnicianDetails() {
    if (serviceDetail == null) {
      return const SizedBox.shrink();
    }

    return _buildDetailCard(
      'Technician Details',
      Column(
        children: [
          _buildDetailRow('Technician Name', serviceDetail!['technician'] ?? ''),
          _buildDetailRow('Employee ID', serviceDetail!['empId'] ?? ''),
          _buildDetailRow('Resolved By ID', serviceDetail!['resolvedBy'] ?? ''),
          _buildDetailRow('Service Date', _formatDateTime(serviceDetail!['timestamp'])),
          _buildDetailRow('Resolution Date', _formatDateTime(serviceDetail!['resolutionTimestamp'])),
          _buildDetailRow('Next Service Date', _formatDate(serviceDetail!['nextServiceDate'])),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSuggestions() {
    if (serviceDetail == null || serviceDetail!['suggestions'] == null) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic> suggestions = serviceDetail!['suggestions'];
    List<Widget> suggestionWidgets = [];

    suggestions.forEach((key, value) {
      if (value == true) {
        String readableKey = key.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        ).toLowerCase();
        readableKey = readableKey[0].toUpperCase() + readableKey.substring(1);
        
        suggestionWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    readableKey,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    if (suggestionWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildDetailCard(
      'Maintenance Suggestions',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: suggestionWidgets,
      ),
    );
  }

  // Helper method to safely extract URLs from different data types
  List<String> _extractUrls(dynamic urlData) {
    if (urlData == null) return [];
    
    if (urlData is List) {
      return urlData
          .where((url) => url != null && url.toString().isNotEmpty)
          .map((url) => url.toString())
          .toList();
    } else if (urlData is String && urlData.isNotEmpty) {
      return [urlData];
    }
    return [];
  }

  // Build photo carousel for specific image type
  Widget _buildPhotoCarousel(List<String> photos, String title, {Color? accentColor}) {
    if (photos.isEmpty) return const SizedBox.shrink();
    
    final PageController pageController = PageController();
    final Color cardColor = accentColor ?? Colors.blue;
    
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForTitle(title),
                  color: cardColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${photos.length} photo${photos.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: pageController,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(photos[index], title),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(photos[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (photos.length > 1) ...[
              const SizedBox(height: 12),
              _buildPhotoIndicators(photos.length, pageController, cardColor),
            ],
          ],
        ),
      ),
    );
  }

  // Build video section
  Widget _buildVideoSection(String? videoUrl, String title, {Color? accentColor}) {
    if (videoUrl == null || videoUrl.isEmpty) return const SizedBox.shrink();
    
    final Color cardColor = accentColor ?? Colors.purple;
    
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.videocam_outlined,
                  color: cardColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cardColor, cardColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardColor),
              ),
              child: InkWell(
                onTap: () => _playVideo(videoUrl, title),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to Play Video',
                      style: TextStyle(
                        color: cardColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build image widget with error handling
  Widget _buildImageWidget(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey.shade400,
                size: 48,
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
    );
  }

  // Build photo indicators
  Widget _buildPhotoIndicators(int count, PageController controller, Color accentColor) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(milliseconds: 100)).map((_) {
        return controller.hasClients ? (controller.page?.round() ?? 0) : 0;
      }),
      builder: (context, snapshot) {
        final currentPage = snapshot.data ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: currentPage == index ? accentColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  // Get appropriate icon for title
  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'front view images':
        return Icons.camera_front_outlined;
      case 'left view images':
        return Icons.rotate_left_outlined;
      case 'right view images':
        return Icons.rotate_right_outlined;
      case 'issue images':
        return Icons.report_problem_outlined;
      case 'resolution images':
        return Icons.check_circle_outline;
      default:
        return Icons.photo_library_outlined;
    }
  }

  // Show full screen image
  void _showFullScreenImage(String imageUrl, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(title, style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Play video
  void _playVideo(String videoUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(
          videoUrl: videoUrl,
          title: title,
        ),
      ),
    );
  }

  // Enhanced image gallery replacement
  Widget _buildEnhancedImageGallery() {
    if (serviceDetail == null) {
      return const SizedBox.shrink();
    }

    // Extract different types of images safely
    final List<String> frontViewImages = _extractUrls(serviceDetail!['frontViewImageUrls']);
    final List<String> leftViewImages = _extractUrls(serviceDetail!['leftViewImageUrls']);
    final List<String> rightViewImages = _extractUrls(serviceDetail!['rightViewImageUrls']);
    final List<String> issueImages = _extractUrls(serviceDetail!['issueImageUrls']);
    final List<String> resolutionImages = _extractUrls(serviceDetail!['resolutionImageUrl']);

    // Extract video URLs safely
    final String? issueVideoUrl = serviceDetail!['issueVideoUrl']?.toString();
    final String? resolutionVideoUrl = serviceDetail!['resolutionVideoUrl']?.toString();

    return Column(
      children: [
        // Front View Images
        _buildPhotoCarousel(
          frontViewImages, 
          'Front View Images',
          accentColor: Colors.blue,
        ),
        
        // Left View Images
        _buildPhotoCarousel(
          leftViewImages, 
          'Left View Images',
          accentColor: Colors.green,
        ),
        
        // Right View Images
        _buildPhotoCarousel(
          rightViewImages, 
          'Right View Images',
          accentColor: Colors.orange,
        ),
        
        // Issue Images
        _buildPhotoCarousel(
          issueImages, 
          'Issue Images',
          accentColor: Colors.red,
        ),
        
        // Resolution Images
        _buildPhotoCarousel(
          resolutionImages, 
          'Resolution Images',
          accentColor: Colors.teal,
        ),
        
        // Issue Video
        _buildVideoSection(
          issueVideoUrl,
          'Issue Video',
          accentColor: Colors.deepPurple,
        ),
        
        // Resolution Video
        _buildVideoSection(
          resolutionVideoUrl,
          'Resolution Video',
          accentColor: Colors.indigo,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: Normalappbar(title: "Service Details"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red[600], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          serviceDetail = await _fetchServiceDetail();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : serviceDetail == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Service details not found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        serviceDetail = await _fetchServiceDetail();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Request Header
                            Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      serviceDetail?['srId'] ?? widget.srNumber,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Status: ${(serviceDetail?['status'] ?? 'pending').toString().replaceAll('_', ' ').toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Complaint Details
                            if (serviceDetail?['customerComplaint'] != null && 
                                serviceDetail!['customerComplaint']!.isNotEmpty)
                              _buildDetailCard(
                                'Complaint Details',
                                buildLabeledContent(
                                  content: serviceDetail!['customerComplaint']!,
                                ),
                              ),

                            // Service Execution Details
                            _buildServiceExecutionDetails(),

                            // Technician Details
                            _buildTechnicianDetails(),

                            // Solution Provided
                            if (serviceDetail?['solutionProvided'] != null && 
                                serviceDetail!['solutionProvided']!.isNotEmpty)
                              _buildDetailCard(
                                'Solution Provided', 
                                buildLabeledContent(
                                  content: serviceDetail!['solutionProvided']!,
                                ),
                              ),

                            // Custom Suggestions
                            if (serviceDetail?['customSuggestions'] != null && 
                                serviceDetail!['customSuggestions']!.isNotEmpty)
                              _buildDetailCard(
                                'Custom Suggestions', 
                                buildLabeledContent(
                                  content: serviceDetail!['customSuggestions']!,
                                ),
                              ),

                            // Maintenance Suggestions
                            _buildMaintenanceSuggestions(),

                            // Enhanced Image Gallery
                            _buildEnhancedImageGallery(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}