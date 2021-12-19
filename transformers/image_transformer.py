import argparse
import kserve

from keras_image_helper import create_preprocessor


class ImageTransformer(kserve.KFModel):
    def __init__(self, name, predictor_host):
        super().__init__(name)
        self.predictor_host = predictor_host
        self.preprocessor = create_preprocessor('xception', target_size=(299, 299))
        self.labels = [
            'dress',
            'hat',
            'longsleeve',
            'outwear',
            'pants',
            'shirt',
            'shoes',
            'shorts',
            'skirt',
            't-shirt'
        ]

    def image_transform(self, instance):
        url = instance['url']
        X = self.preprocessor.from_url(url)
        return X[0].tolist()

    def preprocess(self, inputs):
        instances = [self.image_transform(instance) for instance in inputs['instances']]
        return {'instances': instances}

    def postprocess(self, outputs):
        results = []

        raw = outputs['predictions']

        for row in raw:
            result = {c: p for c, p in zip(self.labels, row)}
            results.append(result)

        return {'predictions': results}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(parents=[kserve.kfserver.parser])
    parser.add_argument('--model_name',
                        help='The name that the model is served under.')
    parser.add_argument('--predictor_host', help='The URL for the model predict function', required=True)

    args, _ = parser.parse_known_args()

    transformer = ImageTransformer(args.model_name, predictor_host=args.predictor_host)
    kserver = kserve.KFServer()
    kserver.start(models=[transformer])