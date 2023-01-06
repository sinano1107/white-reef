/*
 * Copyright 2018 Google LLC. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <CoreLocation/CoreLocation.h>

#include <simd/simd.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A representation of a global transform including location, orientation, altitude, and accuracy
 * estimates. Can be obtained from `GAREarth#cameraGeospatialTransform`, or from
 * `GARSession#geospatialTransformFromTransform:error:`.
 */
@interface GARGeospatialTransform : NSObject

/**
 * Current estimate of horizontal location, specified using the
 * <a href="https://en.wikipedia.org/wiki/World_Geodetic_System">WGS84 specification</a>.
 */
@property(readonly, nonatomic) CLLocationCoordinate2D coordinate;

/**
 * The radius of uncertainty for `GARGeospatialTransform#coordinate`, measured in meters.  The
 * `GARGeospatialTransform#coordinate` identifies the center of the circle, and this value indicates
 * the radius of that circle.
 */
@property(readonly, nonatomic) CLLocationAccuracy horizontalAccuracy;

/**
 * Current estimate of altitude in reference to the
 * <a href="https://en.wikipedia.org/wiki/World_Geodetic_System">WGS84 ellipsoid</a>.
 *
 * Note: This can be compared to
 * <a href="https://developer.apple.com/documentation/corelocation/cllocation/3861801-ellipsoidalaltitude">`CLLocation.ellipsoidalAltitude`</a>,
 * NOT <a href="https://developer.apple.com/documentation/corelocation/cllocation/1423820-altitude">`CLLocation.altitude`</a>.
 */
@property(readonly, nonatomic) CLLocationDistance altitude;

/**
 * The radius of uncertainty for `GARGeospatialTransform#altitude`, measured in meters. The
 * `GARGeospatialTransform#altitude` identifies the mean of the altitude estimate and this value
 * indicates the standard deviation of the estimate.
 */
@property(readonly, nonatomic) CLLocationAccuracy verticalAccuracy;

/**
 * Current estimate of heading. North is 0°, East is 90°, and the angle continues to
 * increase clockwise.  The range is `[0,360)`.
 *
 * This is valid only for `GARGeospatialTransform` from
 * `GAREarth#cameraGeospatialTransform`, and is 0 for all other `GARGeospatialTransform` objects.
 *
 * @deprecated Use `#eastUpSouthQTarget` to get the quaternion from target to East-Up-South (EUS)
 * coordinates instead. To determine a value analogous to the heading value, calculate the yaw,
 * pitch, and roll values from `#eastUpSouthQTarget`. When the device is pointing downwards, i.e.
 * perpendicular to the ground, heading is analoguous to roll, and when the device is upright in the
 * device's default orientation mode, heading is analogous to yaw.
 */
@property(readonly, nonatomic) CLLocationDirection heading
    __attribute__((deprecated("Deprecated in ARCore SDK 1.35. "
                              "See the CHANGELOG to learn more.")));

/**
 * The radius of uncertainty for `GARGeospatialTransform#heading`, measured in degrees.  The
 * `GARGeospatialTransform#heading` identifies the mean of the heading estimate and this value
 * indicates the standard deviation of the estimate.
 *
 * @deprecated This is valid only for `GARGeospatialTransform` from
 * `GAREarth#cameraGeospatialTransform`, and is 0 for all other
 * `GARGeospatialTransform` objects. To get the yaw uncertainty, use `#orientationYawAccuracy`
 * instead, which is analogous to the heading accuracy when the device is held upright in the
 * default orientation mode.
 */
@property(readonly, nonatomic) CLLocationDirectionAccuracy headingAccuracy
    __attribute__((deprecated("Deprecated in ARCore SDK 1.35. "
                              "See the CHANGELOG to learn more.")));

/**
 * The quaternion from the target to East-Up-South (EUS) coordinates
 * (i.e., +X points east, +Y points up, and +Z points south). An identity quaternion will
 * have the target frame oriented such that X+ points to the east, Y+ points up away from the center
 * of the earth, and Z+ points to the south.
 */
@property(readonly, nonatomic) simd_quatf eastUpSouthQTarget;

/**
 * Gets the radius of uncertainty for the orientation's yaw angle accuracy, measured in degrees of
 * standard deviation from the estimate. Yaw rotation is the angle between the transform's compass
 * direction and north, and can be determined from `#eastUpSouthQTarget`.
 *
 */
@property(readonly, nonatomic) CLLocationDirectionAccuracy orientationYawAccuracy;

/// @cond
/**
 * Instantiated by the library.
 */
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
/// @endcond

@end

NS_ASSUME_NONNULL_END
