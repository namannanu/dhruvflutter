import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final baseUrl = _readEnv('JOB_DEBUG_BASE_URL');
  final workerToken = _readEnv('JOB_DEBUG_WORKER_TOKEN');
  final employerToken = Platform.environment['JOB_DEBUG_EMPLOYER_TOKEN'];
  final employerBusinessId = Platform.environment['JOB_DEBUG_EMPLOYER_BUSINESS'];

  if (baseUrl == null || workerToken == null) {
    _printUsage();
    exitCode = 64; // EX_USAGE
    return;
  }

  final query = <String, String>{'status': 'active'};

  final workerJobs = await _fetchJobs(
    baseUrl: baseUrl,
    label: 'worker',
    token: workerToken,
    query: query,
  );

  List<Map<String, dynamic>> employerJobs = const [];
  if (employerToken != null && employerToken.isNotEmpty) {
    employerJobs = await _fetchJobs(
      baseUrl: baseUrl,
      label: 'employer',
      token: employerToken,
      query: query,
      businessId: employerBusinessId,
    );
  }

  final employerIndex = {
    for (final job in employerJobs)
      _string(job['id']) ?? _string(job['_id']) ?? _string(job['jobId']) ?? '': job
  }..removeWhere((key, value) => key.isEmpty);

  stdout.writeln(
    '\nFound ${workerJobs.length} worker jobs and ${employerJobs.length} employer jobs.\n',
  );

  for (final job in workerJobs) {
    final id = _string(job['id']) ?? _string(job['_id']) ?? _string(job['jobId']);
    if (id == null || id.isEmpty) {
      continue;
    }

    final workerSummary = _summarizeJob(job);
    final employerSummary =
        employerIndex.containsKey(id) ? _summarizeJob(employerIndex[id]!) : null;

    stdout.writeln('🔎 Job $id — ${workerSummary.title}');
    stdout.writeln('    Worker address : ${workerSummary.address ?? '(none)'}');
    stdout.writeln('    Worker summary : ${workerSummary.summary ?? '(none)'}');

    if (employerSummary != null) {
      stdout.writeln(
          '    Employer address: ${employerSummary.address ?? '(none)'}');
      stdout.writeln(
          '    Employer summary: ${employerSummary.summary ?? '(none)'}');
    }

    if (employerSummary != null &&
        workerSummary.address != employerSummary.address) {
      stdout.writeln('    ⚠️ Address mismatch detected.');
    }

    if ((workerSummary.address ?? '').isEmpty &&
        (workerSummary.summary ?? '').isEmpty) {
      stdout.writeln('    ⚠️ Worker payload missing location fields.');
    }

    stdout.writeln('');
  }

  stdout.writeln(
    'Done. Provide tokens via JOB_DEBUG_* env vars. Set JOB_DEBUG_EMPLOYER_TOKEN only if you want employer comparison.',
  );
}

void _printUsage() {
  stdout.writeln('''
Usage:
  JOB_DEBUG_BASE_URL=https://api.example.com
  JOB_DEBUG_WORKER_TOKEN=<workerBearerToken>
  [JOB_DEBUG_EMPLOYER_TOKEN=<employerBearerToken>]
  [JOB_DEBUG_EMPLOYER_BUSINESS=<businessId>]
  dart run tool/diagnose_job_addresses.dart
''');
}

Future<List<Map<String, dynamic>>> _fetchJobs({
  required String baseUrl,
  required String label,
  required String token,
  Map<String, String>? query,
  String? businessId,
}) async {
  final uri = _buildUri(baseUrl, '/jobs', query);

  final headers = <String, String>{
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
  if (businessId != null && businessId.isNotEmpty) {
    headers['x-business-id'] = businessId;
  }

  stdout.writeln('➡️  Fetching $label jobs from $uri');
  final response = await http.get(uri, headers: headers);
  stdout.writeln(
      '   $label response: ${response.statusCode} (${response.reasonPhrase})');

  if (response.statusCode >= 400) {
    stdout.writeln('   Body: ${response.body}');
    throw HttpException(
      'Failed to load $label jobs (${response.statusCode})',
      uri: uri,
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is List) {
    return decoded.cast<Map<String, dynamic>>();
  }
  if (decoded is Map<String, dynamic>) {
    final data = decoded['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
  }

  stdout.writeln('   Unexpected response shape: ${response.body}');
  return const [];
}

Uri _buildUri(String baseUrl, String path, Map<String, String>? query) {
  final normalizedBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  final uri = Uri.parse('$normalizedBase$normalizedPath');

  if (query == null || query.isEmpty) {
    return uri;
  }

  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    ...query,
  });
}

String? _readEnv(String key) {
  final value = Platform.environment[key];
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}

String? _string(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

JobSnapshot _summarizeJob(Map<String, dynamic> json) {
  String? deriveLocationAddress(dynamic rawLocation) {
    if (rawLocation is Map<String, dynamic>) {
      String? firstNonEmpty(Iterable<dynamic> values) {
        for (final value in values) {
          if (value == null) continue;
          final text = value.toString().trim();
          if (text.isNotEmpty &&
              text.toLowerCase() != 'null' &&
              text.toLowerCase() != 'undefined') {
            return text;
          }
        }
        return null;
      }

      final line1 = _string(rawLocation['line1']);
      final formatted = _string(rawLocation['formattedAddress']);
      final label = _string(rawLocation['label']) ?? _string(rawLocation['name']);
      final addressMap = rawLocation['address'] is Map<String, dynamic>
          ? rawLocation['address'] as Map<String, dynamic>
          : null;

      return firstNonEmpty([
        line1,
        formatted,
        label,
        [
          line1,
          _string(rawLocation['line2']) ?? _string(addressMap?['line2']),
          _string(rawLocation['city']) ?? _string(addressMap?['city']),
          _string(rawLocation['state']) ?? _string(addressMap?['state']),
        ].whereType<String>().where((segment) => segment.trim().isNotEmpty).join(', '),
      ]);
    }
    return null;
  }

  final title = _string(json['title']) ?? '(untitled)';

  final businessAddress = _string(json['businessAddress']);
  final locationSummary = _string(json['locationSummary']);
  final businessDetails =
      json['businessDetails'] is Map<String, dynamic> ? json['businessDetails'] as Map<String, dynamic> : null;
  final businessDetailsAddress = _string(businessDetails?['address']);
  final location = deriveLocationAddress(json['location']) ??
      deriveLocationAddress(businessDetails?['location']);

  String? firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  final resolvedAddress = firstNonEmpty([
    businessAddress,
    location,
    businessDetailsAddress,
    locationSummary,
  ]);

  return JobSnapshot(
    title: title,
    address: resolvedAddress,
    summary: locationSummary,
  );
}

class JobSnapshot {
  const JobSnapshot({
    required this.title,
    required this.address,
    required this.summary,
  });

  final String title;
  final String? address;
  final String? summary;
}
