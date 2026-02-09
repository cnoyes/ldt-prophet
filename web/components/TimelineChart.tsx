'use client';

import { useMemo } from 'react';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, Legend, ReferenceDot,
} from 'recharts';
import { Apostle, TimelineEntry } from '@/types/apostles';

interface TimelineChartProps {
  timeline: TimelineEntry[];
  apostles: Apostle[];
}

// 15 distinct colors for apostle lines
const LINE_COLORS = [
  '#1f77b4', // blue
  '#ff7f0e', // orange
  '#2ca02c', // green
  '#d62728', // red
  '#9467bd', // purple
  '#8c564b', // brown
  '#e377c2', // pink
  '#7f7f7f', // gray
  '#bcbd22', // olive
  '#17becf', // cyan
  '#393b79', // dark blue
  '#637939', // dark green
  '#8c6d31', // dark gold
  '#843c39', // dark red
  '#7b4173', // dark purple
];

interface CustomTooltipProps {
  active?: boolean;
  label?: string;
  payload?: Array<{
    dataKey: string;
    value: number;
    color: string;
  }>;
}

const CustomTooltip = ({ active, label, payload }: CustomTooltipProps) => {
  if (active && payload && payload.length && label) {
    const date = new Date(label);
    const formattedDate = date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
    });
    const sorted = [...payload]
      .filter((entry) => entry.value > 0.5)
      .sort((a, b) => b.value - a.value);

    return (
      <div className="bg-white p-4 rounded-lg shadow-lg border border-gray-200 max-h-80 overflow-y-auto">
        <p className="font-bold text-gray-900 mb-2">{formattedDate}</p>
        <div className="space-y-1 text-sm">
          {sorted.map((entry) => (
            <p key={entry.dataKey} className="text-gray-700">
              <span
                className="inline-block w-3 h-3 rounded-full mr-2"
                style={{ backgroundColor: entry.color }}
              />
              <span className="font-semibold">{entry.dataKey}:</span>{' '}
              {entry.value.toFixed(1)}%
            </p>
          ))}
        </div>
      </div>
    );
  }
  return null;
};

function formatXAxisTick(dateStr: string) {
  return new Date(dateStr).getFullYear().toString();
}

interface Annotation {
  name: string;
  date: string;
  probability: number;
  color: string;
}

// For each apostle who ever has the highest probability, find the midpoint
// of the segment where they are on top and place a label there.
function computeAnnotations(
  sampled: TimelineEntry[],
  apostleNames: string[],
  colorMap: Record<string, string>
): Annotation[] {
  const topAtPoint = sampled.map((entry) => {
    let maxProb = 0;
    let topName = '';
    for (const name of apostleNames) {
      const prob = (entry[name] as number) || 0;
      if (prob > maxProb) {
        maxProb = prob;
        topName = name;
      }
    }
    return topName;
  });

  const annotations: Annotation[] = [];
  let segStart = 0;

  for (let i = 1; i <= topAtPoint.length; i++) {
    if (i === topAtPoint.length || topAtPoint[i] !== topAtPoint[segStart]) {
      const name = topAtPoint[segStart];
      if (name) {
        const midIdx = Math.floor((segStart + (i - 1)) / 2);
        const entry = sampled[midIdx];
        annotations.push({
          name,
          date: entry.date as string,
          probability: (entry[name] as number) || 0,
          color: colorMap[name],
        });
      }
      segStart = i;
    }
  }

  return annotations;
}

// Custom shape for ReferenceDot: renders a name label with a downward arrow
function AnnotationShape({ cx, cy, color, name }: { cx: number; cy: number; color: string; name: string }) {
  return (
    <g>
      <text
        x={cx}
        y={cy - 30}
        textAnchor="middle"
        fill={color}
        fontSize={11}
        fontWeight="bold"
      >
        {name}
      </text>
      {/* Arrow stem */}
      <line
        x1={cx}
        y1={cy - 18}
        x2={cx}
        y2={cy - 5}
        stroke={color}
        strokeWidth={1.5}
      />
      {/* Arrow head pointing down */}
      <polygon
        points={`${cx},${cy - 3} ${cx - 3.5},${cy - 9} ${cx + 3.5},${cy - 9}`}
        fill={color}
      />
    </g>
  );
}

export default function TimelineChart({ timeline, apostles }: TimelineChartProps) {
  const apostleNames = apostles.map((a) => a.lastName);

  const colorMap = useMemo(() => {
    const map: Record<string, string> = {};
    apostleNames.forEach((name, idx) => {
      map[name] = LINE_COLORS[idx % LINE_COLORS.length];
    });
    return map;
  }, [apostleNames]);

  const sampled = useMemo(
    () => timeline.filter((_, i) => i % 3 === 0 || i === timeline.length - 1),
    [timeline]
  );

  const annotations = useMemo(
    () => computeAnnotations(sampled, apostleNames, colorMap),
    [sampled, apostleNames, colorMap]
  );

  const yearTicks = sampled
    .filter((entry) => new Date(entry.date as string).getMonth() === 0)
    .map((entry) => entry.date);

  return (
    <div className="w-full h-full">
      <h3 className="text-lg font-bold text-gray-900 mb-4 text-center">
        Prophet Probability Over Time
      </h3>
      <p className="text-sm text-gray-600 mb-6 text-center">
        Probability of being the current church president at each point in time
      </p>
      <ResponsiveContainer width="100%" height={500}>
        <LineChart data={sampled} margin={{ top: 40, right: 20, left: 0, bottom: 20 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
          <XAxis
            dataKey="date"
            tickFormatter={formatXAxisTick}
            ticks={yearTicks}
            tick={{ fontSize: 11 }}
          />
          <YAxis
            domain={[0, 100]}
            tick={{ fontSize: 11 }}
            width={40}
            tickFormatter={(value: number) => `${value}%`}
          />
          <Tooltip content={<CustomTooltip />} />
          <Legend
            itemSorter={null}
            wrapperStyle={{ fontSize: '11px', paddingTop: '10px' }}
          />
          {apostleNames.map((name, idx) => (
            <Line
              key={name}
              type="monotone"
              dataKey={name}
              stroke={LINE_COLORS[idx % LINE_COLORS.length]}
              strokeWidth={2}
              dot={false}
              activeDot={{ r: 4 }}
            />
          ))}
          {annotations.map((ann, i) => (
            <ReferenceDot
              key={`ann-${i}`}
              x={ann.date}
              y={ann.probability}
              r={0}
              fill="transparent"
              stroke="transparent"
              shape={(props: any) => (
                <AnnotationShape
                  cx={props.cx}
                  cy={props.cy}
                  color={ann.color}
                  name={ann.name}
                />
              )}
            />
          ))}
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
