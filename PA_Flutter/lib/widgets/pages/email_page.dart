import 'package:flutter/material.dart';

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final List<Email> _emails = [
    Email(sender: 'Google', subject: 'Security Alert', body: 'A new device has signed in to your account.'),
    Email(sender: 'Flutter Team', subject: 'Flutter Newsletter', body: 'Check out the latest news from the Flutter team.'),
  ];

  Email? _selectedEmail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement compose email functionality
            },
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 250,
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
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
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
                        const Divider(),
                        Text(_selectedEmail!.body),
                      ],
                    ),
                  )
                : const Center(
                    child: Text('Select an email to read'),
                  ),
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