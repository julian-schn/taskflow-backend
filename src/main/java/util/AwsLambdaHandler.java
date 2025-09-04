package util;

import com.amazonaws.serverless.exceptions.ContainerInitializationException;
import com.amazonaws.serverless.proxy.model.AwsProxyRequest;
import com.amazonaws.serverless.proxy.model.AwsProxyResponse;
import com.amazonaws.serverless.proxy.spring.SpringLambdaContainerHandler;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.taskflow.taskflowbackend.TaskflowBackendApplication;

/**
 * AWS Lambda handler that integrates Spring Boot application with AWS Lambda using 
 * the AWS Serverless Java Container.
 * 
 * This handler allows the Spring Boot application to run in AWS Lambda by proxying
 * HTTP requests through the Spring Boot application context.
 * 
 * Configuration:
 * - Handler: util.AwsLambdaHandler::handleRequest
 * - Runtime: java17 or java21
 * - Memory: Recommended 512MB+ for Spring Boot apps
 * - Timeout: 30+ seconds for cold starts
 * - Environment Variables: Set SPRING_PROFILES_ACTIVE=lambda
 */
public class AwsLambdaHandler implements RequestHandler<AwsProxyRequest, AwsProxyResponse> {

    private static SpringLambdaContainerHandler<AwsProxyRequest, AwsProxyResponse> handler;

    static {
        try {
            // Initialize the Spring Boot Lambda container handler
            handler = SpringLambdaContainerHandler.getAwsProxyHandler(TaskflowBackendApplication.class);
            
            // Configure the handler for optimal Lambda performance
            handler.activateSpringProfiles("lambda");
            
            // Enable request and response logging for debugging (optional)
            // handler.getContainerConfig().setRequestMetricsLogger(new DefaultRequestMetricsLogger());
            
        } catch (ContainerInitializationException e) {
            // Re-throw as runtime exception if initialization fails
            throw new RuntimeException("Could not initialize Spring Boot Lambda handler", e);
        }
    }

    @Override
    public AwsProxyResponse handleRequest(AwsProxyRequest awsProxyRequest, Context context) {
        // Proxy the request to the Spring Boot application
        return handler.proxy(awsProxyRequest, context);
    }
}
