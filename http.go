package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	pb "github.com/GoogleCloudPlatform/microservices-demo/src/frontend/genproto/hipstershop"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"io/ioutil"
	"math/rand"
)

func (fe *frontendServer) getAdByHttp(ctx context.Context, ctxKeys []string) *pb.Ad {
	var buffer bytes.Buffer
	buffer.WriteString(fmt.Sprintf("http://%s/ads", fe.adSvcAddrHttp))

	for i, ctxKey := range ctxKeys {
		if i == 0 {
			buffer.WriteString(fmt.Sprintf("?category=%s", ctxKey))
		} else {
			buffer.WriteString(fmt.Sprintf("&category=%s", ctxKey))
		}
	}

	resp, err := otelhttp.Get(ctx, fmt.Sprintf(buffer.String()))
	if err != nil {
		log.WithField("error", err).Warn("failed to retrieve ads")
		return nil
	}
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.WithField("error", err).Warn("Error read body from request")
		return nil
	}
	var ar AdResponse

	err = json.Unmarshal([]byte(body), &ar)
	if err != nil {
		log.WithField("error", err).Warn("Error unmarshaling data from request.")
		return nil
	}

	grpcAr := ar.Ads[rand.Intn(len(ar.Ads))]

	return &pb.Ad{
		RedirectUrl: grpcAr.RedirectUrl,
		Text:        grpcAr.Text,
	}
}

func (fe *frontendServer) getRecommendationsByHttp(ctx context.Context, userID string, productIDs []string) (error, *RecommendationList) {
	var buffer bytes.Buffer
	buffer.WriteString(fmt.Sprintf("http://%s/listrecomendation", fe.adSvcRecomendationHttp))

	buffer.WriteString(fmt.Sprintf("?user_id=%s", userID))

	for i, productID := range productIDs {
		if i == 0 {
			buffer.WriteString(fmt.Sprintf("&product_ids=%s", productID))
		} else {
			buffer.WriteString(fmt.Sprintf(",%s", productID))
		}
	}

	log.Infof(fmt.Sprintf("Buffer: %s ", buffer.String()))

	resp, err := otelhttp.Get(ctx, fmt.Sprintf(buffer.String()))
	if err != nil {
		log.WithField("error", err).Warn("failed to recommendations list")
		return err, &RecommendationList{}
	}
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.WithField("error", err).Warn("Error read body from request")
		return err, &RecommendationList{}
	}
	var recommendationsList *RecommendationList

	err = json.Unmarshal([]byte(body), &recommendationsList)
	if err != nil {
		log.WithField("error", err).Warn("Error unmarshaling data from request.")
		return err, &RecommendationList{}
	}

	return nil, recommendationsList
}
