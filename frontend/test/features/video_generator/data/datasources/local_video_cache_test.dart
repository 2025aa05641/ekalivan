import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textbook_video_learning/features/video_generator/data/datasources/local_video_cache.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_job_entity.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('getAll returns an empty list when nothing has been cached', () async {
    const LocalVideoCache cache = LocalVideoCache();

    expect(await cache.getAll(), isEmpty);
  });

  test('saveCompletedJob persists a job retrievable via getAll', () async {
    const LocalVideoCache cache = LocalVideoCache();

    await cache.saveCompletedJob(
      const VideoJobEntity(taskId: 'job-1', status: 'COMPLETED', videoUrl: '/static/video/job-1/final.mp4'),
    );
    final List<VideoJobEntity> cached = await cache.getAll();

    expect(cached, hasLength(1));
    expect(cached.single.taskId, 'job-1');
    expect(cached.single.videoUrl, '/static/video/job-1/final.mp4');
  });

  test('saveCompletedJob replaces an existing entry for the same taskId', () async {
    const LocalVideoCache cache = LocalVideoCache();

    await cache.saveCompletedJob(const VideoJobEntity(taskId: 'job-1', status: 'COMPLETED', videoUrl: '/old.mp4'));
    await cache.saveCompletedJob(const VideoJobEntity(taskId: 'job-1', status: 'COMPLETED', videoUrl: '/new.mp4'));
    final List<VideoJobEntity> cached = await cache.getAll();

    expect(cached, hasLength(1));
    expect(cached.single.videoUrl, '/new.mp4');
  });

  test('saveCompletedJob keeps distinct jobs, most recently saved first', () async {
    const LocalVideoCache cache = LocalVideoCache();

    await cache.saveCompletedJob(const VideoJobEntity(taskId: 'job-1', status: 'COMPLETED', videoUrl: '/a.mp4'));
    await cache.saveCompletedJob(const VideoJobEntity(taskId: 'job-2', status: 'COMPLETED', videoUrl: '/b.mp4'));
    final List<VideoJobEntity> cached = await cache.getAll();

    expect(cached.map((VideoJobEntity job) => job.taskId).toList(), <String>['job-2', 'job-1']);
  });
}
