// ignore_for_file: prefer_single_quotes

import 'package:flutter/material.dart';

class Worker {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> skills;
  final double rating;
  final String experience;
  final List<String> languages;
  final bool isVerified;
  final int completedJobs;
  final String bio;
  final double weeklyEarnings;
  final double totalEarnings;

  Worker({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.skills,
    required this.rating,
    required this.experience,
    required this.languages,
    required this.isVerified,
    required this.completedJobs,
    required this.bio,
    required this.weeklyEarnings,
    required this.totalEarnings,
  });
}

class WorkerProfile extends StatefulWidget {
  final Worker worker;
  final VoidCallback onSignOut;
  final Function(Worker) onUpdateProfile;

  const WorkerProfile({
    super.key,
    required this.worker,
    required this.onSignOut,
    required this.onUpdateProfile,
  });

  @override
  State<WorkerProfile> createState() => _WorkerProfileState();
}

class _WorkerProfileState extends State<WorkerProfile> {
  bool isEditing = false;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController bioController;
  late TextEditingController skillsController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.worker.name);
    phoneController = TextEditingController(text: widget.worker.phone);
    bioController = TextEditingController(text: widget.worker.bio);
    skillsController = TextEditingController(text: widget.worker.skills.join(", "));
  }

  void handleSave() {
    final updatedWorker = Worker(
      id: widget.worker.id,
      name: nameController.text,
      email: widget.worker.email,
      phone: phoneController.text,
      skills: skillsController.text.split(",").map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      rating: widget.worker.rating,
      experience: widget.worker.experience,
      languages: widget.worker.languages,
      isVerified: widget.worker.isVerified,
      completedJobs: widget.worker.completedJobs,
      bio: bioController.text,
      weeklyEarnings: widget.worker.weeklyEarnings,
      totalEarnings: widget.worker.totalEarnings,
    );
    widget.onUpdateProfile(updatedWorker);
    setState(() => isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => setState(() => isEditing = !isEditing),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: widget.onSignOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue,
                          child: Text(
                            widget.worker.name.split(" ").map((e) => e[0]).join(),
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (widget.worker.isVerified)
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.green,
                              child: Icon(Icons.verified, size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          isEditing
                              ? TextField(controller: nameController)
                              : Text(widget.worker.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.yellow, size: 16),
                              Text("${widget.worker.rating}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Text("(24 reviews)", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const Row(
                            children: [
                              Icon(Icons.location_pin, size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Text("Downtown area", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const Row(
                            children: [
                              Icon(Icons.circle, size: 10, color: Colors.green),
                              SizedBox(width: 4),
                              Text("Available now", style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bio
            buildSection(
              "Bio",
              isEditing
                  ? TextField(controller: bioController, maxLines: 3)
                  : Text(widget.worker.bio),
            ),

            // Contact
            buildSection(
              "Contact",
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Email: ${widget.worker.email}"),
                  isEditing
                      ? TextField(controller: phoneController)
                      : Text("Phone: ${widget.worker.phone}"),
                ],
              ),
            ),

            if (isEditing)
              Row(
                children: [
                  ElevatedButton(onPressed: handleSave, child: const Text("Save")),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: () => setState(() => isEditing = false), child: const Text("Cancel")),
                ],
              ),

            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(child: buildStat("${widget.worker.completedJobs}", "Jobs Completed", Colors.blue)),
                Expanded(child: buildStat("98%", "On-time Rate", Colors.green)),
                Expanded(child: buildStat("2.1", "Years Exp", Colors.purple)),
              ],
            ),

            const SizedBox(height: 16),

            // Earnings
            buildSection(
              "Earnings",
              Column(
                children: [
                  rowText("This Week", "\$${widget.worker.weeklyEarnings}"),
                  rowText("Total Earned", "\$${widget.worker.totalEarnings}"),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () {}, child: const Text("Withdraw Earnings")),
                ],
              ),
            ),

            // Skills
            buildSection(
              "Skills",
              isEditing
                  ? TextField(controller: skillsController)
                  : Wrap(
                      spacing: 8,
                      children: widget.worker.skills.map((s) => Chip(label: Text(s))).toList(),
                    ),
            ),

            // Languages
            buildSection(
              "Languages",
              Wrap(
                spacing: 8,
                children: widget.worker.languages.map((lang) => Chip(label: Text(lang))).toList(),
              ),
            ),

            // Availability
            buildSection(
              "Availability",
              const Column(
                children: [
                  ListTile(title: Text("Weekdays"), trailing: Text("6:00 AM - 10:00 PM")),
                  ListTile(title: Text("Weekends"), trailing: Text("8:00 AM - 12:00 AM")),
                ],
              ),
            ),

            // Reviews
            buildSection(
              "Recent Reviews",
              const Column(
                children: [
                  ListTile(title: Text("Mario's Kitchen"), subtitle: Text("Excellent worker! Always on time.")),
                  ListTile(title: Text("FreshMart"), subtitle: Text("Great with customers, would hire again.")),
                ],
              ),
            ),

            // Account
            buildSection(
              "Account",
              Column(
                children: [
                  ListTile(
                    title: const Text("Payment Settings"),
                    subtitle: const Text("Manage how you receive payments"),
                    onTap: () {},
                  ),
                  ListTile(
                    title: const Text("Notification Settings"),
                    subtitle: const Text("Control job alerts and updates"),
                    onTap: () {},
                  ),
                  ListTile(
                    title: const Text("Sign Out", style: TextStyle(color: Colors.red)),
                    subtitle: const Text("Sign out of your account", style: TextStyle(color: Colors.red)),
                    onTap: widget.onSignOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSection(String title, Widget child) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }

  Widget buildStat(String value, String label, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget rowText(String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(left, style: const TextStyle(color: Colors.grey)),
        Text(right, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
