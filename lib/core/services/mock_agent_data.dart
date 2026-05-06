import 'package:flutter/material.dart';
import '../models/agent_session.dart';
import '../models/agent_status.dart';

/// Mock data provider for development
class MockAgentData {
  MockAgentData._();

  /// Get 4 mock agents for development
  static List<AgentSession> getMockAgents() {
    return [
      AgentSession(
        id: 'main-agent',
        name: 'Marvis',
        role: 'main',
        status: AgentStatus.live,
        currentTask: 'Heartbeat + Chat',
        progress: 0.8,
        steps: ['Processing messages', 'Monitoring system'],
        lastActive: DateTime.now().subtract(const Duration(seconds: 30)),
        startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      AgentSession(
        id: 'coding-agent',
        name: 'Cody',
        role: 'coding',
        status: AgentStatus.busy,
        currentTask: 'ClawChat Development',
        progress: 0.95,
        steps: ['Implementing AgentCard', 'Adding animations', 'Testing UI'],
        lastActive: DateTime.now().subtract(const Duration(minutes: 2)),
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AgentSession(
        id: 'research-agent',
        name: 'Deep Search',
        role: 'research',
        status: AgentStatus.idle,
        currentTask: 'Ready to work',
        progress: 0.0,
        steps: [],
        lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      AgentSession(
        id: 'autotask-agent',
        name: 'AutoTask',
        role: 'autotask',
        status: AgentStatus.live,
        currentTask: 'Daily research + updates',
        progress: 0.5,
        steps: ['Checking emails', 'Updating calendar', 'Sending reports'],
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
        startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];
  }
}
