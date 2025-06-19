FROM eclipse-temurin:17-jdk
WORKDIR /app
COPY . .
RUN apt-get update && apt-get install -y maven
RUN mvn clean package -DskipTests
CMD ["java", "-jar", "target/desktop-client-1.0-SNAPSHOT.jar"]
