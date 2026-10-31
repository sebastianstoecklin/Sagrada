public let stableAeroSpaceAppId: String = "com.sebastianstoecklin.sagradaspace"
#if DEBUG
    public let aeroSpaceAppId: String = "com.sebastianstoecklin.sagradaspace.debug"
    public let aeroSpaceAppName: String = "SagradaSpaceDebug"
#else
    public let aeroSpaceAppId: String = stableAeroSpaceAppId
    public let aeroSpaceAppName: String = "SagradaSpace"
#endif
