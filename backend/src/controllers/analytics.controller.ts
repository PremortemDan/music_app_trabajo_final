import { Response } from 'express';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export async function getCreatorMetrics(req: AuthRequest, res: Response): Promise<void> {
  try {
    const ownerId = req.userId!;

    // Obtener todas las canciones del creador
    const songs = await prisma.song.findMany({
      where: { ownerId },
      select: { id: true, title: true, plays: true },
      orderBy: { plays: 'desc' },
    });

    const totalPlays = songs.reduce((sum, s) => sum + s.plays, 0);

    // Reprods por canción (porcentaje y datos para gráficos)
    const songsWithPercentage = songs.map((s) => ({
      id: s.id,
      title: s.title,
      plays: s.plays,
      percentage: totalPlays > 0 ? Math.round((s.plays / totalPlays) * 1000) / 10 : 0,
    }));

    // Views diarias últimos 30 días
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const dailyStreams = await prisma.streamRecord.groupBy({
      by: ['createdAt'],
      where: {
        ownerId,
        createdAt: { gte: thirtyDaysAgo },
      },
      _count: { id: true },
      orderBy: { createdAt: 'asc' },
    });

    // Agrupar por día
    const dailyMap = new Map<string, number>();
    const now = new Date();
    for (let i = 29; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const key = d.toISOString().split('T')[0];
      dailyMap.set(key, 0);
    }

    dailyStreams.forEach((ds) => {
      const key = ds.createdAt.toISOString().split('T')[0];
      if (dailyMap.has(key)) {
        dailyMap.set(key, (dailyMap.get(key) || 0) + ds._count.id);
      }
    });

    const dailyChart: { date: string; views: number }[] = [];
    dailyMap.forEach((views, date) => {
      dailyChart.push({ date, views });
    });
    dailyChart.sort((a, b) => a.date.localeCompare(b.date));

    // Top canciones
    const topSongs = songs.slice(0, 10).map((s, i) => ({
      rank: i + 1,
      id: s.id,
      title: s.title,
      plays: s.plays,
    }));

    // Países de oyentes
    const countryStreams = await prisma.streamRecord.groupBy({
      by: ['country'],
      where: {
        ownerId,
        country: { not: null },
      },
      _count: { id: true },
      orderBy: { _count: { id: 'desc' } },
      take: 15,
    });

    const countries = countryStreams.map((c) => ({
      country: c.country || 'Desconocido',
      count: c._count.id,
      percentage: totalPlays > 0 ? Math.round((c._count.id / totalPlays) * 1000) / 10 : 0,
    }));

    // Streams por hora del día
    const hourlyStreams = await prisma.$queryRawUnsafe<{ hour: number; count: bigint }[]>(
      `SELECT EXTRACT(HOUR FROM created_at)::int as hour, COUNT(*)::bigint as count
       FROM stream_records
       WHERE owner_id = $1 AND created_at >= $2
       GROUP BY hour
       ORDER BY hour`,
      ownerId,
      thirtyDaysAgo
    );

    const hourlyChart: { hour: number; views: number }[] = [];
    for (let h = 0; h < 24; h++) {
      hourlyChart.push({ hour: h, views: 0 });
    }
    hourlyStreams.forEach((hs) => {
      hourlyChart[hs.hour] = { hour: hs.hour, views: Number(hs.count) };
    });

    // Streams por día de la semana
    const weekdayStreams = await prisma.$queryRawUnsafe<{ dow: number; count: bigint }[]>(
      `SELECT EXTRACT(DOW FROM created_at)::int as dow, COUNT(*)::bigint as count
       FROM stream_records
       WHERE owner_id = $1 AND created_at >= $2
       GROUP BY dow
       ORDER BY dow`,
      ownerId,
      thirtyDaysAgo
    );

    const weekdayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    const weekdayChart: { day: string; views: number }[] = weekdayNames.map((d) => ({
      day: d,
      views: 0,
    }));
    weekdayStreams.forEach((ws) => {
      weekdayChart[ws.dow] = { day: weekdayNames[ws.dow], views: Number(ws.count) };
    });

    // Totales generales
    const totalStreamsLast30 = dailyChart.reduce((sum, d) => sum + d.views, 0);
    const avgDaily = totalStreamsLast30 > 0 ? Math.round(totalStreamsLast30 / 30) : 0;
    const bestDay = dailyChart.reduce((max, d) => (d.views > max.views ? d : max), dailyChart[0]);

    res.json({
      totalSongs: songs.length,
      totalPlays,
      songsWithPercentage,
      dailyChart,
      topSongs,
      countries,
      hourlyChart,
      weekdayChart,
      summary: {
        totalStreamsLast30,
        avgDaily,
        bestDay: bestDay
          ? { date: bestDay.date, views: bestDay.views }
          : { date: '', views: 0 },
      },
    });
  } catch (error) {
    console.error('Error en analytics:', error);
    res.status(500).json({ error: 'Error al obtener métricas' });
  }
}