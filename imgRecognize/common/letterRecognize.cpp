
//#include <opencv2/core/utility.hpp>
#include "opencv2/imgproc.hpp"
//#include "opencv2/imgcodecs.hpp"
#include "opencv2/highgui.hpp"
#include <dirent.h>
#include <math.h>

#include "letterRecognize.h"


////////////////////////////////////////////////////////////////////
//structs
////////////////////////////////////////////////////////////////////
typedef struct {
    char c;
    cv::Mat img;
} StringTmplPair;

typedef struct _MatchResult{
    
    _MatchResult() { relativeVal = 0; }
    
    StringTmplPair* pair;
    cv::Rect rect;
    double relativeVal;
} MatchResult;

typedef std::vector<StringTmplPair*> TmplPairs;
typedef std::vector<MatchResult*> MatchResults;


////////////////////////////////////////////////////////////////////
//datas
////////////////////////////////////////////////////////////////////
static TmplPairs Pairs;

////////////////////////////////////////////////////////////////////
//function apis
////////////////////////////////////////////////////////////////////
cv::Rect matchingMethod(const cv::Mat& img, const cv::Mat& templ, const int match_method, double& resVal);
const TmplPairs generatorTmplPairs(const cv::String& path);
char getCharaterFromName(const char* name);
void checkAndInsert(const MatchResult* result, MatchResults& results);
cv::Rect intersectedRect(const cv::Rect& r1, const cv::Rect& r2);
cv::String getStringFromImg(const cv::Mat& src, const TmplPairs& tmpls);
bool isContainRect(const cv::Rect& cRect, const cv::Rect& tRect);


////////////////////////////////////////////////////////////////////
//apis implement
////////////////////////////////////////////////////////////////////

///////////////////////////////////////////public api
bool initImgRecognizer(const char* tmplImgPath)
{
    Pairs = generatorTmplPairs(tmplImgPath);
    return true;
}

const char* getStringFromImg(const char* imgPath)
{
    cv::Mat src = cv::imread(imgPath);
    cv::String resStr = getStringFromImg(src, Pairs);
    
    char* pStr = new char[resStr.length() + 1];
    strcpy(pStr, resStr.c_str());
    pStr[resStr.length()] = '\0';
    
    return pStr;
}

///////////////////////////////////////////private api
cv::Rect matchingMethod(const cv::Mat& img, const cv::Mat& templ, const int match_method, double& resVal)
{
    /// Create the result matrix
    int result_cols =  img.cols - templ.cols + 1;
    int result_rows = img.rows - templ.rows + 1;
    
    cv::Mat result;
    result.create( result_rows, result_cols, CV_32FC1 );
        
    /// Do the Matching and Normalize
    cv::matchTemplate( img, templ, result, match_method );
    //cv::normalize( result, result, 0, 1, cv::NORM_MINMAX, -1, cv::Mat() );
    
    /// Localizing the best match with minMaxLoc
    double minVal; double maxVal; cv::Point minLoc; cv::Point maxLoc; cv::Point matchLoc;
    cv::minMaxLoc( result, &minVal, &maxVal, &minLoc, &maxLoc, cv::Mat() );
    
    
    /// For SQDIFF and SQDIFF_NORMED, the best matches are lower values. For all the other methods, the higher the better
    if( match_method  == cv::TM_SQDIFF || match_method == cv::TM_SQDIFF_NORMED )
    {
        matchLoc = minLoc;
        resVal = minVal;
    }
    else
    {
        matchLoc = maxLoc;
        resVal = maxVal;
    }
    
    return cv::Rect(matchLoc, cv::Point( matchLoc.x + templ.cols , matchLoc.y + templ.rows ));
}

const TmplPairs generatorTmplPairs(const cv::String& path)
{
    TmplPairs pairs;
    dirent* dirp = NULL;
    DIR* dP = opendir(path.c_str());
    while (NULL != (dirp = readdir(dP))) {
        char c = getCharaterFromName(dirp->d_name);
        if (-1 != c) {
            StringTmplPair* onePair = new StringTmplPair();
            cv::String filePath = path  + dirp->d_name;
            onePair->c = c;
            onePair->img = cv::imread(filePath);
            cv:assert(0 != onePair->img.rows && 0 != onePair->img.cols);
            pairs.push_back(onePair);
        }
    }
    
    return pairs;
}

char getCharaterFromName(const char* name)
{
    char resC = -1;
    std::string imgName(name);
    if (imgName.length() > 4 && imgName.substr(imgName.length() - 4, 4) == ".png") {
        imgName = imgName.substr(0, imgName.length() - 4);
        const char* str = imgName.c_str();
        if (1 == imgName.length()) {
            resC = str[0];
        } else if (3 == imgName.length()) {
            if ('s' == str[0]) {
                resC = tolower(str[2]);
            } else if ('b' == str[0]) {
                resC = toupper(str[2]);
            }
        }
    }
    
    return resC;
}

bool isContainRect(const cv::Rect& cRect, const cv::Rect& tRect)
{
    cv::Rect cRectTmpl(cRect.tl(), cv::Size(cRect.width + 1, cRect.height));
    bool res = cRectTmpl.contains(tRect.tl());
    res &= cRectTmpl.contains(tRect.br());
    return res;
}

cv::String getStringFromImg(const cv::Mat& src, const TmplPairs& tmpls)
{
    const int letter_count = 4;
    const double smallestVal = 0.83;
    cv::Mat cloneSrc = src.clone();
    //src.convertTo(<#OutputArray m#>, <#int rtype#>)
    MatchResults results;

    for (int count = 0; count < letter_count; count++) {
        MatchResult* res = NULL;
        TmplPairs::const_iterator it = tmpls.begin();
        while (tmpls.end() != it) {
            double tempVal;
            cv::Rect rect = matchingMethod(cloneSrc, (*it)->img, cv::TM_CCOEFF_NORMED, tempVal);
            if (tempVal > smallestVal) {
                res = NULL == res ? new MatchResult() : res;
                float tempRat = 1.f;
                const int xNearbyLimit = 4;
                if (abs(res->rect.tl().x - rect.tl().x) < xNearbyLimit)
                {
                    tempRat = sqrtf((float)rect.width / res->rect.width);
                    tempRat = sqrtf(tempRat);
                }
                if (res->relativeVal < tempVal * tempRat /*&& !isContainRect(res->rect, rect)*/) {
                    res->rect = rect;
                    res->relativeVal = tempVal;
                    res->pair = (*it);
                }
            }
            it++;
        }
        if (NULL != res) {
            checkAndInsert(res, results);
            cv::rectangle(cloneSrc, res->rect, cv::Scalar(0, 0, 255));
        }
    }
    
    cv::String resStr;
    MatchResults::const_iterator it = results.begin();
    while (results.end() != it) {
        resStr += (*it)->pair->c;
        it++;
    }
    
    return resStr;
}

void checkAndInsert(const MatchResult* result, MatchResults& results)
{
    bool inserted = false;
    MatchResults::const_iterator it = results.begin();
    while (results.end() != it) {
        if (result->rect.tl().x < (*it)->rect.tl().x) {
            results.insert(it, const_cast<MatchResult*>(result));
            inserted = true;
            break;
        }
        it++;
    }

    if(false == inserted) {
        results.push_back(const_cast<MatchResult*>(result));
    }
}


cv::Rect intersectedRect(const cv::Rect& r1, const cv::Rect& r2)
{
    cv::Rect resRect;
    cv::Point delta = r2.br() - r1.tl();
    if (0 < delta.x && delta.x < (r1.width + r2.width) &&
        -(r1.height + r2.height) < delta.y && delta.y < 0) {
        resRect = cv::Rect(cv::Point(MAX(r1.tl().x, r2.tl().x), MIN(r1.tl().y, r2.tl().y)),
                           cv::Point(MIN(r1.br().x, r2.br().x), MAX(r1.br().y, r2.br().y))
                           );
    }
    
    return resRect;
}


