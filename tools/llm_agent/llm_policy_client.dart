import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../sim/llm_action_schema.dart';

class LlmPolicyClientConfig {
  const LlmPolicyClientConfig({
    required this.model,
    required this.temperature,
    required this.topP,
    required this.timeoutSeconds,
    required this.requestDir,
    required this.responseDir,
  });

  final String model;
  final double temperature;
  final double topP;
  final int timeoutSeconds;
  final String requestDir;
  final String responseDir;
}

class LlmPolicyClientResult {
  const LlmPolicyClientResult({
    required this.response,
    required this.latencyMs,
    required this.error,
  });

  final Map<String, dynamic>? response;
  final int latencyMs;
  final String? error;
}

Future<LlmPolicyClientResult> requestLocalLlmAction({
  required LlmActionRequest request,
  required LlmPolicyClientConfig config,
}) async {
  return requestLocalJsonAction(requestJson: request.toJson(), config: config);
}

Future<LlmPolicyClientResult> requestLocalJsonAction({
  required Map<String, dynamic> requestJson,
  required LlmPolicyClientConfig config,
}) async {
  final requestId = requestJson['request_id'] as String? ?? 'llm_request';
  final safeId = requestId.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  final requestPath = '${config.requestDir}/$safeId.json';
  final responsePath = '${config.responseDir}/$safeId.json';
  final requestFile = File(requestPath)..parent.createSync(recursive: true);
  requestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(requestJson),
  );
  final started = DateTime.now();
  try {
    final result = await Process.run('python3', [
      'tools/llm_agent/run_llm_policy.py',
      '--input',
      requestPath,
      '--out',
      responsePath,
      '--backend',
      'ollama',
      '--model',
      config.model,
      '--temperature',
      config.temperature.toString(),
      '--top-p',
      config.topP.toString(),
      '--timeout-seconds',
      config.timeoutSeconds.toString(),
    ]).timeout(Duration(seconds: config.timeoutSeconds + 10));
    final latencyMs = DateTime.now().difference(started).inMilliseconds;
    if (result.exitCode != 0) {
      return LlmPolicyClientResult(
        response: null,
        latencyMs: latencyMs,
        error: 'runner_exit_${result.exitCode}',
      );
    }
    final response = jsonDecode(File(responsePath).readAsStringSync());
    if (response is Map<String, dynamic>) {
      return LlmPolicyClientResult(
        response: response,
        latencyMs: latencyMs,
        error: null,
      );
    }
    return LlmPolicyClientResult(
      response: null,
      latencyMs: latencyMs,
      error: 'non_object_response',
    );
  } on TimeoutException {
    return LlmPolicyClientResult(
      response: null,
      latencyMs: DateTime.now().difference(started).inMilliseconds,
      error: 'runner_timeout',
    );
  } catch (error) {
    return LlmPolicyClientResult(
      response: null,
      latencyMs: DateTime.now().difference(started).inMilliseconds,
      error: error.runtimeType.toString(),
    );
  }
}
