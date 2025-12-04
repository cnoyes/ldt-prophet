import { promises as fs } from 'fs';
import path from 'path';
import AgeChart from '@/components/AgeChart';
import ProbabilityChart from '@/components/ProbabilityChart';
import { ApostlesData } from '@/types/apostles';

async function getApostlesData(): Promise<ApostlesData> {
  const filePath = path.join(process.cwd(), 'public', 'apostles.json');
  const fileContents = await fs.readFile(filePath, 'utf8');
  return JSON.parse(fileContents);
}

export default async function Home() {
  const data = await getApostlesData();

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-1 sm:px-4 py-8">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-blue-900 mb-2">
            Prophet Probability Tracker
          </h1>
          <p className="text-lg text-gray-600">
            Statistical analysis of succession probabilities in the Quorum of the Twelve Apostles
          </p>
          <p className="text-sm text-gray-500 mt-2">
            Last updated: {new Date(data.metadata.generatedAt).toLocaleDateString('en-US', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
              hour: '2-digit',
              minute: '2-digit'
            })}
          </p>
        </div>

        {/* Info Box */}
        <div className="bg-blue-50 border-l-4 border-blue-900 p-6 mb-8 rounded-md">
          <h2 className="text-lg font-semibold text-blue-900 mb-2">
            ℹ️ About This Tool
          </h2>
          <p className="text-gray-700">
            This application uses actuarial science and Monte Carlo simulation ({data.metadata.simulationRuns.toLocaleString()} runs) to estimate
            the probability that each apostle will eventually become President of The Church of Jesus Christ of Latter-day Saints.
            Calculations are based on current ages, seniority (ordination dates), and CDC life expectancy data.
          </p>
        </div>

        {/* Charts Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <div className="bg-white p-1 sm:p-6 rounded-lg shadow-md">
            <AgeChart apostles={data.apostles} />
          </div>
          <div className="bg-white p-1 sm:p-6 rounded-lg shadow-md">
            <ProbabilityChart apostles={data.apostles} />
          </div>
        </div>

        {/* Key Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white p-6 rounded-lg shadow-md text-center">
            <div className="text-3xl font-bold text-blue-900 mb-2">
              {data.metadata.totalApostles}
            </div>
            <div className="text-gray-600">Total Apostles</div>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-md text-center">
            <div className="text-3xl font-bold text-blue-900 mb-2">
              {Math.round(data.apostles.reduce((sum, a) => sum + a.age, 0) / data.apostles.length)}
            </div>
            <div className="text-gray-600">Average Age</div>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-md text-center">
            <div className="text-3xl font-bold text-blue-900 mb-2">
              {data.metadata.simulationRuns.toLocaleString()}
            </div>
            <div className="text-gray-600">Simulation Runs</div>
          </div>
        </div>

        {/* Disclaimer */}
        <div className="bg-yellow-50 border-l-4 border-yellow-600 p-6 rounded-md">
          <p className="text-gray-700">
            <strong>⚠️ Disclaimer:</strong> These probabilities are statistical estimates for educational purposes only.
            They do not represent official church doctrine or predictions. Apostolic succession is determined by seniority
            and inspiration, not probability.
          </p>
        </div>

        {/* Footer */}
        <div className="text-center mt-12 text-gray-500 text-sm">
          <p>Prophet Probability Tracker | Statistical analysis for educational purposes only</p>
          <p className="mt-2">
            Not affiliated with The Church of Jesus Christ of Latter-day Saints |{' '}
            <a
              href="https://github.com/cnoyes/apostles"
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 hover:underline"
            >
              View on GitHub
            </a>
          </p>
        </div>
      </div>
    </div>
  );
}
