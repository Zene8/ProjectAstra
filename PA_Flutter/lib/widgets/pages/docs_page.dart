import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:projectastra/services/document_service.dart'; // New DocumentService
import 'package:projectastra/models/document_models.dart'; // New Document models
import 'package:provider/provider.dart'; // Import Provider
import 'package:projectastra/services/auth_service.dart'; // Import AuthService

enum DocumentProvider {
  googleDrive,
  oneDrive,
}

class DocsPage extends StatefulWidget {
  const DocsPage({super.key});

  @override
  State<DocsPage> createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
  DocumentProvider _selectedDocumentProvider = DocumentProvider.googleDrive; // Default to Google Drive
  late DocumentService _documentService; // Declare DocumentService

  final QuillController _controller = QuillController.basic();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Editor'),
      ),
      body: QuillEditor.basic(
        controller: _controller,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _documentService = DocumentService(Provider.of<AuthService>(context, listen: false));
      _listDocuments(); // List documents on init
    });
  }

  Future<void> _listDocuments() async {
    try {
      final fetchedDocuments = await _documentService.listDocuments(_selectedDocumentProvider.toString().split('.').last);
      setState(() {
        // TODO: Store fetched documents and display them in a list
        // For now, just print
        print('Fetched documents: $fetchedDocuments');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load documents: $e')),
      );
    }
  }

  Future<void> _downloadDocument(String documentId) async {
    try {
      final content = await _documentService.downloadDocumentContent(_selectedDocumentProvider.toString().split('.').last, documentId);
      _controller.document = Document.fromJson(jsonDecode(content)).toDelta(); // Assuming content is Delta JSON
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document downloaded and loaded.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download document: $e')),
      );
    }
  }

  Future<void> _uploadDocument(String fileName, String content) async {
    try {
      final newDoc = await _documentService.uploadDocument(_selectedDocumentProvider.toString().split('.').last, fileName, content);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document uploaded: ${newDoc.title}')),
      );
      _listDocuments(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload document: $e')),
      );
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    try {
      await _documentService.deleteDocument(_selectedDocumentProvider.toString().split('.').last, documentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted.')),
      );
      _listDocuments(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Editor'),
        actions: [
          DropdownButton<DocumentProvider>(
            value: _selectedDocumentProvider,
            onChanged: (DocumentProvider? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedDocumentProvider = newValue;
                });
                _listDocuments(); // List documents for the new provider
              }
            },
            items: const <DropdownMenuItem<DocumentProvider>>[
              DropdownMenuItem<DocumentProvider>((
                value: DocumentProvider.googleDrive,
                child: Text('Google Drive'),
              ),
              DropdownMenuItem<DocumentProvider>(
                value: DocumentProvider.oneDrive,
                child: Text('OneDrive'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Implement save current document
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Save functionality not implemented yet.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // TODO: Add a list view for documents here
          Expanded(
            child: QuillEditor.basic(
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
