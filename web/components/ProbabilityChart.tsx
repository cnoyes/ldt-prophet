'use client';

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Apostle } from '@/types/apostles';

interface ProbabilityChartProps {
  apostles: Apostle[];
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: Array<{
    payload: Apostle;
  }>;
}

const CustomTooltip = ({ active, payload }: CustomTooltipProps) => {
  if (active && payload && payload.length) {
    const apostle = payload[0].payload;
    return (
      <div className="bg-white p-4 rounded-lg shadow-lg border border-gray-200">
        <p className="font-bold text-gray-900 mb-2">{apostle.fullName}</p>
        <div className="space-y-1 text-sm">
          {apostle.probabilityPercent !== undefined && (
            <p className="text-gray-700 font-semibold text-lg">
              {apostle.probabilityPercent}% chance
            </p>
          )}
          <p className="text-gray-700">
            <span className="font-semibold">Age:</span> {Math.floor(apostle.age)} years
          </p>
          <p className="text-gray-700">
            <span className="font-semibold">Years in Quorum:</span> {apostle.yearsInQuorum}
          </p>
          <p className="text-gray-700">
            <span className="font-semibold">Seniority:</span> #{apostle.seniority}
          </p>
          <p className="text-gray-700">
            <span className="font-semibold">Ordained:</span>{' '}
            {new Date(apostle.ordinationDate).toLocaleDateString('en-US', {
              year: 'numeric',
              month: 'long',
              day: 'numeric'
            })}
          </p>
        </div>
      </div>
    );
  }
  return null;
};

export default function ProbabilityChart({ apostles }: ProbabilityChartProps) {
  // Filter out the first apostle (current president) who has no probability
  const data = apostles
    .filter((apostle) => apostle.probability !== undefined)
    .map((apostle) => ({
      ...apostle,
      name: apostle.lastName,
      displayProb: apostle.probabilityPercent || 0
    }));

  return (
    <div className="w-full h-full">
      <h3 className="text-lg font-bold text-gray-900 mb-4 text-center">
        Succession Probability
      </h3>
      <p className="text-sm text-gray-600 mb-6 text-center">
        Based on actuarial life expectancy modeling
      </p>
      <ResponsiveContainer width="100%" height={400}>
        <BarChart data={data} margin={{ top: 20, right: 5, left: 5, bottom: 80 }}>
          <defs>
            <linearGradient id="probGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#0C4A6E" stopOpacity={1} />
              <stop offset="100%" stopColor="#BAE6FD" stopOpacity={1} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
          <XAxis
            dataKey="name"
            angle={-45}
            textAnchor="end"
            height={100}
            tick={{ fontSize: 10 }}
            interval={0}
          />
          <YAxis domain={[0, 100]} tick={{ fontSize: 10 }} />
          <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(0, 0, 0, 0.05)' }} />
          <Bar
            dataKey="displayProb"
            fill="url(#probGradient)"
            radius={[4, 4, 0, 0]}
            label={{
              position: 'top',
              formatter: (value: any) => `${Math.round(Number(value))}%`,
              fontSize: 10,
              fontWeight: 'bold',
              fill: '#000'
            }}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
