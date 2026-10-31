public let stableAeroSpaceAppId: String = "com.sebastianstoecklin.sagrada"
#if DEBUG
    public let aeroSpaceAppId: String = "com.sebastianstoecklin.sagrada.debug"
    public let aeroSpaceAppName: String = "SagradaDebug"
#else
    public let aeroSpaceAppId: String = stableAeroSpaceAppId
    public let aeroSpaceAppName: String = "Sagrada"
#endif
