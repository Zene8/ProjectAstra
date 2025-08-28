import 'package:flutter/material.dart';
import 'package:projectastra/services/email_service.dart'; // New EmailService
import 'package:projectastra/models/email_models.dart'; // New Email models
import 'package:provider/provider.dart'; // Import Provider
import 'package:projectastra/services/auth_service.dart'; // Import AuthService

enum EmailProvider {
  gmail,
  outlook,
}

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  EmailProvider _selectedEmailProvider = EmailProvider.gmail; // Default to Gmail
  late EmailService _emailService; // Declare EmailService

  final List<Email> _emails = [
    Email(sender: 'Google', subject: 'Security Alert', body: 'A new device has signed in to your account.'),
    Email(sender: 'Flutter Team', subject: 'Flutter Newsletter', body: 'Check out the latest news from the Flutter team.'),
  ];

  Email? _selectedEmail;

  @override
  void initState() {
    super.initState();
    // Initialize EmailService here, after context is available
    // This assumes AuthService is provided higher up in the widget tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailService = EmailService(Provider.of<AuthService>(context, listen: false));
      _fetchEmails(); // Fetch emails on init
    });
  }

  Future<void> _fetchEmails() async {
    try {
      final fetchedEmails = await _emailService.fetchEmails(_selectedEmailProvider.toString().split('.').last);
      setState(() {
        _emails.clear();
        _emails.addAll(fetchedEmails);
        _selectedEmail = _emails.isNotEmpty ? _emails.first : null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load emails: $e')),
      );
    }
  }

  Future<void> _composeEmail() async {
    // TODO: Implement compose email functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compose email not implemented yet.')),
    );
    // Example of sending email:
    // await _emailService.sendEmail(
    //   _selectedEmailProvider.toString().split('.').last,
    //   'recipient@example.com',
    //   'Test Subject',
    //   'Test Body',
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email'),
        actions: [
          DropdownButton<EmailProvider>(
            value: _selectedEmailProvider,
            onChanged: (EmailProvider? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedEmailProvider = newValue;
                });
                _fetchEmails(); // Fetch emails for the new provider
              }
            },
            items: const <DropdownMenuItem<EmailProvider>>[
              DropdownMenuItem<EmailProvider>(
                value: EmailProvider.gmail,
                child: Text('Gmail'),
              ),
              DropdownMenuItem<EmailProvider>(
                value: EmailProvider.outlook,
                child: Text('Outlook'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _composeEmail,
          ),
        ],
      ),
      body: Row(
        children: [
          // Email List
          SizedBox(
            width: 300, // Fixed width for email list
            child: ListView.builder(
              itemCount: _emails.length,
              itemBuilder: (context, index) {
                final email = _emails[index];
                return ListTile(
                  title: Text(email.sender),
                  subtitle: Text(email.subject),
                  onTap: () {
                    setState(() {
                      _selectedEmail = email;
                    });
                  },
                  selected: _selectedEmail == email,
                );
              },
            ),
          ),
          // Email Detail
          Expanded(
            child: _selectedEmail != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('From: ${_selectedEmail!.sender}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Subject: ${_selectedEmail!.subject}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(_selectedEmail!.body),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(child: Text('Select an email to read')),
          ),
        ],
      ),
    );
  }
}

class Email {
  final String sender;
  final String subject;
  final String body;

  Email({required this.sender, required this.subject, required this.body});
}