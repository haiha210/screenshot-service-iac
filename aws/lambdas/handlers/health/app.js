/**
 * Health Check Lambda Handler
 * Provides service health status and basic system information
 */

exports.handler = async (event) => {
    console.log('Health check request received:', JSON.stringify(event, null, 2));

    try {
        const healthStatus = await checkHealth();

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,OPTIONS'
            },
            body: JSON.stringify(healthStatus)
        };
    } catch (error) {
        console.error('Health check failed:', error);

        return {
            statusCode: 503,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                status: 'unhealthy',
                message: error.message,
                timestamp: new Date().toISOString()
            })
        };
    }
};

/**
 * Perform health checks
 */
async function checkHealth() {
    const startTime = Date.now();

    // Get basic system info
    const memoryUsage = process.memoryUsage();
    const uptime = process.uptime();

    // Check environment variables
    const serviceName = process.env.SERVICE_NAME || 'unknown';
    const environment = process.env.ENVIRONMENT || 'unknown';
    const awsRegion = process.env.AWS_REGION || 'unknown';

    // Perform basic checks
    const checks = {
        memory: checkMemory(memoryUsage),
        runtime: checkRuntime()
    };

    const allHealthy = Object.values(checks).every(check => check.status === 'ok');
    const responseTime = Date.now() - startTime;

    return {
        status: allHealthy ? 'healthy' : 'degraded',
        service: serviceName,
        environment: environment,
        region: awsRegion,
        timestamp: new Date().toISOString(),
        uptime: Math.floor(uptime),
        responseTime: responseTime,
        checks: checks,
        version: process.env.VERSION || '1.0.0',
        runtime: process.version
    };
}

/**
 * Check memory usage
 */
function checkMemory(memoryUsage) {
    const usedMB = Math.round(memoryUsage.heapUsed / 1024 / 1024);
    const totalMB = Math.round(memoryUsage.heapTotal / 1024 / 1024);
    const usagePercent = Math.round((memoryUsage.heapUsed / memoryUsage.heapTotal) * 100);

    return {
        status: usagePercent < 90 ? 'ok' : 'warning',
        used: `${usedMB}MB`,
        total: `${totalMB}MB`,
        percentage: `${usagePercent}%`
    };
}

/**
 * Check Node.js runtime
 */
function checkRuntime() {
    const nodeVersion = process.version;
    const majorVersion = parseInt(nodeVersion.split('.')[0].substring(1));

    return {
        status: majorVersion >= 18 ? 'ok' : 'warning',
        version: nodeVersion,
        platform: process.platform,
        arch: process.arch
    };
}
