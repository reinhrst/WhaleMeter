//
//  conversion.c
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 18/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//


// copied from:
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
/*  Ordnance Survey Grid Reference functions  (c) Chris Veness 2005-2014                          */
/*   - www.movable-type.co.uk/scripts/gridref.js                                                  */
/*   - www.movable-type.co.uk/scripts/latlon-gridref.html                                         */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */


#include <stdio.h>
#define _USE_MATH_DEFINES
#include <math.h>
#define DEG_TO_RAD .0174532925199432958
#define RAD_TO_DEG 57.29577951308232

struct ellipsoid {
    double a;
    double b;
    double f;
};

struct transform {
    double tx;
    double ty;
    double tz;
    double rx;
    double ry;
    double rz;
    double s;
};

struct datum {
    struct ellipsoid ellipsoid;
    struct transform transform;
};

#define ELLIPSOID_WGS84        ((struct ellipsoid) \
    { .a = 6378137,     .b = 6356752.3142,   .f = 1/298.257223563 })
#define ELLIPSOID_Airy1830        ((struct ellipsoid) \
    { .a = 6377563.396, .b = 6356256.909,    .f = 1/299.3249646   })

#define DATUM_OSGB36 ((struct datum) { .ellipsoid = ELLIPSOID_Airy1830, \
.transform = (struct transform) {    .tx = -446.448,  .ty = 125.157,   .tz = -542.060, \
                                    .rx = -0.1502,   .ry = -0.2470,   .rz = -0.8421, \
                                    .s = 20.4894 }})

#define DATUM_WGS84 ((struct datum) { .ellipsoid = ELLIPSOID_WGS84, \
.transform = (struct transform) { 0,0,0,  0,0,0,  0}})

void polarToCartesian(double *x, double *y, double* z, struct datum* datum);
void cartesianToPolar(double *x, double *y, double* z, struct datum* datum);
void helmertTransform(double *x, double *y, double* z, struct datum* fromdatum, struct datum* todatum);

void convertDatum(double* x, double* y, double* z, struct datum* fromDatum, struct datum* todatum){
    polarToCartesian(x,y,z, fromDatum);
    helmertTransform(x,y,z, fromDatum, todatum);
    cartesianToPolar(x,y,z, todatum);
}


void polarToCartesian(double *x, double *y, double* z, struct datum* datum){
    double phi = *x * DEG_TO_RAD, lambda = *y * DEG_TO_RAD, H=*z;
    double a = datum->ellipsoid.a, b = datum->ellipsoid.b;
    
    double sinphi = sin(phi);
    double cosphi = cos(phi);
    double sinlambda = sin(lambda);
    double coslambda = cos(lambda);
    
    double eSq = (a*a - b*b) / (a*a);
    double nu = a / sqrt(1 - eSq*sinphi*sinphi);
    
    *x = (nu+H) * cosphi * coslambda;
    *y = (nu+H) * cosphi * sinlambda;
    *z = ((1-eSq)*nu + H) * sinphi;
}

void cartesianToPolar(double *x, double *y, double* z, struct datum* datum){
    double a = datum->ellipsoid.a, b = datum->ellipsoid.b;
    
    double eSq = (a*a - b*b) / (a*a);
    double p = sqrt(*x* *x + *y* *y);
    double phi = atan2(*z, p*(1-eSq)), phiP = 2*M_PI;
    double nu = 0;
    
    double precision = 4 / a;  // results accurate to around 4 metres
    while (fabs(phi-phiP) > precision) {
        nu = a / sqrt(1 - eSq*sin(phi)*sin(phi));
        phiP = phi;
        phi = atan2(*z + eSq*nu*sin(phi), p);
    }
    
    double lambda = atan2(*y, *x);
    double H = p/cos(phi) - nu;
    
    *x = phi * RAD_TO_DEG;
    *y = lambda * RAD_TO_DEG;
    *z = H;
}

void helmertTransform(double *x, double *y, double* z, struct datum* fromdatum, struct datum* todatum){
    double x1 = *x, y1 = *y, z1 = *z;
    
    double tx = todatum->transform.tx - fromdatum->transform.tx;
    double ty = todatum->transform.ty - fromdatum->transform.ty;
    double tz = todatum->transform.tz - fromdatum->transform.tz;
    double rx = ((todatum->transform.rx - fromdatum->transform.rx)/3600)*DEG_TO_RAD;  // normalise seconds to radians
    double ry = ((todatum->transform.ry - fromdatum->transform.ry)/3600)*DEG_TO_RAD;
    double rz = ((todatum->transform.rz - fromdatum->transform.rz)/3600)*DEG_TO_RAD;
    double s1 = (todatum->transform.s - fromdatum->transform.s)/1e6 + 1;          // normalise ppm to (s+1)
    
    // apply transform
    double x2 = tx + x1*s1 - y1*rz + z1*ry;
    double y2 = ty + x1*rz + y1*s1 - z1*rx;
    double z2 = tz - x1*ry + y1*rx + z1*s1;
    
    *x = x2;
    *y = y2;
    *z = z2;
}

/**
 * Convert (OSGB36) latitude/longitude to Ordnance Survey grid reference easting/northing coordinate
 *
 * @param x,y: long, lat
 * @return x,y contain easting/northing
 */

void latLongToOsGrid(double* x, double* y) {
    double lat = *x * DEG_TO_RAD;
    double lon = *y * DEG_TO_RAD;
    
    double a = 6377563.396, b = 6356256.909;          // Airy 1830 major & minor semi-axes
    double F0 = 0.9996012717;                         // NatGrid scale factor on central meridian
    double lat0 = 49 * DEG_TO_RAD , lon0 = -2 * DEG_TO_RAD;  // NatGrid true origin is 49N,2W
    int N0 = -100000, E0 = 400000;                 // northing & easting of true origin, metres
    double e2 = 1 - (b*b)/(a*a);                      // eccentricity squared
    double n = (a-b)/(a+b), n2 = n*n, n3 = n*n*n;
    
    double cosLat = cos(lat), sinLat = sin(lat);
    double nu = a*F0/sqrt(1-e2*sinLat*sinLat);              // transverse radius of curvature
    double rho = a*F0*(1-e2)/pow(1-e2*sinLat*sinLat, 1.5);  // meridional radius of curvature
    double eta2 = nu/rho-1;
    
    double Ma = (1 + n + (5/4)*n2 + (5/4)*n3) * (lat-lat0);
    double Mb = (3*n + 3*n*n + (21/8)*n3) * sin(lat-lat0) * cos(lat+lat0);
    double Mc = ((15/8)*n2 + (15/8)*n3) * sin(2*(lat-lat0)) * cos(2*(lat+lat0));
    double Md = (35/24)*n3 * sin(3*(lat-lat0)) * cos(3*(lat+lat0));
    double M = b * F0 * (Ma - Mb + Mc - Md);              // meridional arc

    double cos3lat = cosLat*cosLat*cosLat;
    double cos5lat = cos3lat*cosLat*cosLat;
    double tan2lat = tan(lat)*tan(lat);
    double tan4lat = tan2lat*tan2lat;
    
    double I = M + N0;
    double II = (nu/2)*sinLat*cosLat;
    double III = (nu/24)*sinLat*cos3lat*(5-tan2lat+9*eta2);
    double IIIA = (nu/720)*sinLat*cos5lat*(61-58*tan2lat+tan4lat);
    double IV = nu*cosLat;
    double V = (nu/6)*cos3lat*(nu/rho-tan2lat);
    double VI = (nu/120) * cos5lat * (5 - 18*tan2lat + tan4lat + 14*eta2 - 58*tan2lat*eta2);
    
    double dLon = lon-lon0;
    double dLon2 = dLon*dLon, dLon3 = dLon2*dLon, dLon4 = dLon3*dLon, dLon5 = dLon4*dLon, dLon6 = dLon5*dLon;
    
    double N = I + II*dLon2 + III*dLon4 + IIIA*dLon6;
    double E = E0 + IV*dLon + V*dLon3 + VI*dLon5;
    
    *x = E;
    *y = N;
}


/**
 * Convert Ordnance Survey grid reference easting/northing coordinate to (OSGB36) latitude/longitude
 *
 * @param {OsGridRef} easting/northing to be converted to latitude/longitude
 * @return {LatLon} latitude/longitude (in OSGB36) of supplied grid reference
 */
void osGridToLatLong(double* x, double* y) {
    double E = *x;
    double N = *y;
    
    double a = 6377563.396, b = 6356256.909;              // Airy 1830 major & minor semi-axes
    double F0 = 0.9996012717;                             // NatGrid scale factor on central meridian
    double lat0 = 49 * M_PI/180, lon0 = -2 * M_PI/180;  // NatGrid true origin
    double N0 = -100000, E0 = 400000;                     // northing & easting of true origin, metres
    double e2 = 1 - (b*b)/(a*a);                          // eccentricity squared
    double n = (a-b)/(a+b), n2 = n*n, n3 = n*n*n;
    
    double lat=lat0, M=0;
    do {
        lat = (N-N0-M)/(a*F0) + lat;
        
        double Ma = (1 + n + (5/4)*n2 + (5/4)*n3) * (lat-lat0);
        double Mb = (3*n + 3*n*n + (21/8)*n3) * sin(lat-lat0) * cos(lat+lat0);
        double Mc = ((15/8)*n2 + (15/8)*n3) * sin(2*(lat-lat0)) * cos(2*(lat+lat0));
        double Md = (35/24)*n3 * sin(3*(lat-lat0)) * cos(3*(lat+lat0));
        M = b * F0 * (Ma - Mb + Mc - Md);                // meridional arc
        
    } while (N-N0-M >= 0.00001);  // ie until < 0.01mm
    
    double cosLat = cos(lat), sinLat = sin(lat);
    double nu = a*F0/sqrt(1-e2*sinLat*sinLat);              // transverse radius of curvature
    double rho = a*F0*(1-e2)/pow(1-e2*sinLat*sinLat, 1.5);  // meridional radius of curvature
    double eta2 = nu/rho-1;
    
    double tanLat = tan(lat);
    double tan2lat = tanLat*tanLat, tan4lat = tan2lat*tan2lat, tan6lat = tan4lat*tan2lat;
    double secLat = 1/cosLat;
    double nu3 = nu*nu*nu, nu5 = nu3*nu*nu, nu7 = nu5*nu*nu;
    double VII = tanLat/(2*rho*nu);
    double VIII = tanLat/(24*rho*nu3)*(5+3*tan2lat+eta2-9*tan2lat*eta2);
    double IX = tanLat/(720*rho*nu5)*(61+90*tan2lat+45*tan4lat);
    double X = secLat/nu;
    double XI = secLat/(6*nu3)*(nu/rho+2*tan2lat);
    double XII = secLat/(120*nu5)*(5+28*tan2lat+24*tan4lat);
    double XIIA = secLat/(5040*nu7)*(61+662*tan2lat+1320*tan4lat+720*tan6lat);
    
    double dE = (E-E0), dE2 = dE*dE, dE3 = dE2*dE, dE4 = dE2*dE2, dE5 = dE3*dE2, dE6 = dE4*dE2, dE7 = dE5*dE2;
    lat = lat - VII*dE2 + VIII*dE4 - IX*dE6;
    double lon = lon0 + X*dE - XI*dE3 + XII*dE5 - XIIA*dE7;
    
    *x = lat * RAD_TO_DEG;
    *y = lon * RAD_TO_DEG;
}

void WGS84toOSGB36(double* x, double* y) {
    double z = 0.0;
    struct datum fromdatum = DATUM_WGS84, todatum = DATUM_OSGB36;
    convertDatum(x,y, &z, &fromdatum, &todatum);
    latLongToOsGrid(x,y);
}

