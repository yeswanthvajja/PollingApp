FROM maven:3.9.5-eclipse-temurin-17 AS build

WORKDIR /app


COPY pom.xml .
RUN mvn dependency:go-offline -B


COPY src ./src
RUN mvn clean package -DskipTests



FROM eclipse-temurin:17-jre

WORKDIR /app


RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*


RUN groupadd -r spring && useradd -r -g spring spring


COPY --from=build /app/target/polling-app-1.0.0.jar app.jar
RUN chown spring:spring app.jar

USER spring:spring


EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]

# Set active profile to production (can be overridden)
ENV SPRING_PROFILES_ACTIVE=prod
